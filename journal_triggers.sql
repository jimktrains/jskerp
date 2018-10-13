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
declare
  unbalanced_entries int;
begin
  select count(*) into unbalanced_entries
    from (select entry_id
      from new_postings
      group by entry_id
      having sum(quantity) <> 0
    ) x;
  if unbalanced_entries is not null and unbalanced_entries > 0 then
   raise exception '% Journal Entry(ies) Not Balanced', unbalanced_entries;
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

