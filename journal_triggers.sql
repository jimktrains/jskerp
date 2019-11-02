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

create function check_measure_increment()
returns trigger
as $$
declare
  diff numeric(10,4);
  uom_incremental numeric(10,4);
  uom_name text;
begin
  select incremental,
         name
  into uom_incremental,
       uom_name
  from unit_of_measure
  where unit_of_measure_id = new.unit_of_measure_id;

  if diff <> 0 then
    raise '% is not an increment of % for % (uom=%) (%)', new.measure, uom_incremental, uom_name, new.unit_of_measure_id, diff;
  end if;

  return new;
end;
$$ language plpgsql;

create trigger trigger_account_check_measure
before insert or update
on account
for each row
execute procedure check_measure_increment();

create trigger trigger_posting_check_measure
before insert or update
on posting
for each row
execute procedure check_measure_increment();
