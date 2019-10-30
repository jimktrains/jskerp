set search_path to inventory, public;

create or replace function function_update_inventory_quantity ()
returns trigger
as $$
begin
  update account
  set quantity = account.quantity + new_postings.quantity
  from new_postings
  where account.account_id = new_postings.account_id;

  return new;
end;
$$ language plpgsql;

create trigger trigger_update_inventory_quantity
after insert
on posting
referencing new table as new_postings
for each statement
execute procedure function_update_inventory_quantity();

create or replace function function_check_zero_balance_journal_entry ()
returns trigger
as $$
begin
    if exists(
      select
      from new_postings
      group by entry_id, sku
      having sum(quantity * measure) <> 0
    ) then
   raise exception 'Journal Entry(ies) Not Balanced';
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

create or replace function function_check_new_entity_is_new ()
returns trigger
as $$
declare
  table_posting_count int;
  new_posting_count int;
begin
  select count(*) into table_posting_count
  from posting
  where entry_id in (select distinct entry_id from new_postings);

  select count(*) into new_posting_count
  from new_postings;

  if table_posting_count <> new_posting_count then
   raise exception 'All postings must be for a new entry % <> %', table_posting_count, new_posting_count ;
  end if;

  return new;
end;
$$ language plpgsql;

create trigger trigger_check_new_entity_is_new
after insert
on posting
referencing new table as new_postings
for each statement
execute procedure function_check_new_entity_is_new();
