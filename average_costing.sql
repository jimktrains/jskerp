SET search_path TO inventory, public;

-- Average costing is computed whenever inventory is added to an
-- account. The current average cost of the credit and debit account
-- are averaged weighted by the current inventory in the credit account
-- and the quantity being moved, respectivly.

create table account_average_cost (
  account_id bigint primary key references account(account_id),
  average_cost numeric(10,4) not null default 0
);

create or replace function function_new_average_cost_on_new_account ()
returns trigger
as $$
begin
  insert into account_average_cost
  (account_id)
  select account_id
  from new_accounts;

  return new;
end;
$$ language plpgsql;

create trigger trigger_new_average_cost_on_new_account
after insert
on account
referencing new table as new_accounts
for each statement
execute procedure function_new_average_cost_on_new_account();

create or replace function function_update_average_cost ()
returns trigger
as $$
begin
  -- Compute the average cost of all items of a sku being debited, using
  -- any unit_cost set on the debit.
  with new_postings_debit_avg_unit_cost AS (
    select entry_id,
           sku,
           sum(abs(quantity * measure) * coalesce(unit_cost, average_cost))/sum(abs(quantity * measure)) as posting_avg_unit_cost
    from new_postings
    join account_average_cost using (account_id)
    where quantity < 0
    group by entry_id, sku
  ),
  -- Compute the new average costs for inventory going into each of the credit
  -- accounts.
  account_credit_avg_unit_cost AS (
    select account_id,
           sum(quantity * measure) as credit_quantity_measure,
           sum(quantity * measure * posting_avg_unit_cost) / sum(quantity * measure) as credit_avg_cost
    from new_postings
    join new_postings_debit_avg_unit_cost using (entry_id, sku)
    where quantity * measure > 0
    group by account_id
  ),
  -- Compute the new average cost of the credit account.
  account_credit_avg_cost AS (
    select account_id,
           ((credit_quantity_measure * credit_avg_cost) + (quantity * measure * average_cost))/(credit_quantity_measure+ (quantity * measure)) as new_account_avg_cost
    from account_credit_avg_unit_cost
    join account using (account_id)
    join account_average_cost using (account_id)
  )
  update account_average_cost
  set average_cost = new_account_avg_cost
  from account_credit_avg_cost
  where account_average_cost.account_id = account_credit_avg_cost.account_id;

  return new;
end;
$$ language plpgsql;

create trigger trigger_update_average_cost
after insert
on posting
referencing new table as new_postings
for each statement
execute procedure function_update_average_cost();
