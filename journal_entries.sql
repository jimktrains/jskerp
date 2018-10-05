create or replace function function_update_inventory_amount ()
returns trigger
as $$
begin
  update inventory
  set amount = inventory.amount + new_postings.amount
  from new_postings
  where inventory.inventory_id = new_postings.inventory_id;

  return new;
end;
$$ language plpgsql;

create trigger trigger_update_inventory_amount
after insert
on posting
referencing new table as new_postings
for each statement
execute procedure function_update_inventory_amount();

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

