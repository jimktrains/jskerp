create type account_types as enum ('replenish', 'inventory', 'committed', 'picked', 'shipped');
create type order_item_statuses as enum ('ordered', 'committed', 'picked', 'shipped');

create table account (
  account_id bigserial primary key,
  item_id bigint not null,
  account_type account_types not null,
  amount integer not null,
  description text,
  unique (item_id, account_type)
);

create table journal (
  entry_id bigserial primary key,
  order_id bigint,
  description text,
  created_at timestamp not null default current_timestamp
);

create table posting (
  -- Yes, this might have gaps :(
  posting_id bigserial primary key,
  entry_id bigint not null references journal,
  account_id bigint not null references account,
  amount integer not null
);

create table order_item (
  order_item_id bigserial primary key,
  item_id bigint not null,
  order_id bigint not null,
  status order_item_statuses not null default 'ordered'
);

create or replace function allocate_order_item()
returns trigger
as $$
begin
  with journal_ordered as (
    insert into journal (order_id)
    select distinct order_id
    from new_order_item
    order by order_id
    returning *
  ),
  journaled_items as (
    select
        entry_id,
        potential_inventory_to_commit.item_id,
        order_id,
        item_count,
        inventory_account.account_id as inventory_account_id,
        committed_account.account_id as committed_account_id
    from (
      select
        entry_id,
        counted_items.item_id,
        counted_items.order_id,
        item_count,
        sum(item_count) over (order by entry_id rows between unbounded preceding and 1 preceding) as inventory_commited
      from (
        select
          item_id,
          order_id,
          count(*) as item_count
        from new_order_item
        group by item_id, order_id
      ) as counted_items
      join journal_ordered
        on journal_ordered.order_id = counted_items.order_id
    ) potential_inventory_to_commit
    join account inventory_account
      on inventory_account.item_id = potential_inventory_to_commit.item_id
        and inventory_account.account_type = 'inventory'
    join account committed_account
      on inventory_account.item_id = potential_inventory_to_commit.item_id
        and committed_account.account_type = 'committed'
    where item_count <= (inventory_account.amount - coalesce(inventory_commited, 0))
  ),
  postings as (
    insert into posting (entry_id, account_id, amount)
    select
      entry_id,
      inventory_account_id as account_id,
      (-1 * item_count) as amount
    from journaled_items
    union all
    select
      entry_id,
      committed_account_id as account_id,
      item_count as amount
    from journaled_items
    returning *
  ),
  posted_items as (
    select item_id, order_id
    from postings
    join journaled_items
      on journaled_items.inventory_account_id = postings.account_id
      and journaled_items.entry_id = postings.entry_id
  )
  update order_item
  set status = 'committed'
  from posted_items
  where posted_items.item_id = order_item.item_id
    and posted_items.order_id = order_item.order_id;

  return new;
end;
$$ language plpgsql;

create trigger trigger_commit_order_items
after insert
on order_item
referencing new table as new_order_item
for each statement
execute procedure allocate_order_item();


create or replace function function_update_account_amount ()
returns trigger
as $$
begin
  update account
  set amount = account.amount + new_postings.amount
  from new_postings
  where account.account_id = new_postings.account_id;

  return new;
end;
$$ language plpgsql;

create trigger trigger_update_account_amount
after insert
on posting
referencing new table as new_postings
for each statement
execute procedure function_update_account_amount();

create or replace function function_check_zero_balance_journal_entry ()
returns trigger
as $$
declare
  unbalanced_entries text;
begin
  select string_agg(entry_id::text, ', ') into unbalanced_entries
    from (select entry_id
      from new_postings
      group by entry_id
      having sum(amount) <> 0
    ) x;
  if unbalanced_entries is not null then
   raise exception 'Journal Entries % Not Balanced', unbalanced_entries;
  end if;

  return new;
end;
$$ language plpgsql;

create trigger trigger_check_zero_balance_journal_entry
after insert
on posting
referencing new table as new_postings
for each statement
execute procedure function_check_zero_balance_journal_entry();

create or replace function function_check_journal_in_this_tx()
returns trigger
as $$
declare
  unbalanced_entries text;
begin
  select string_agg(entry_id::text, ', ') into unbalanced_entries
    from (select entry_id
      from journal
      where
            entry_id IN (select entry_id from new_postings)
        and xmin::text <> txid_current()::text
    ) x;
  if unbalanced_entries is not null then
   raise exception 'Journal Entries % Not Created In This Transaction', unbalanced_entries;
  end if;

  return new;
end;
$$ language plpgsql;

create trigger trigger_check_journal_in_this_tx
after insert
on posting
referencing new table as new_postings
for each statement
execute procedure function_check_journal_in_this_tx();
