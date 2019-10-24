SET search_path TO inventory, public;

create table account_average_cost (
  account_id bigint primary key references account(account_id),
  average_cost numeric(10,4) not null default 0
);

create or replace function function_update_average_cost ()
returns trigger
as $$
begin
  with new_postings_debit_avg_unit_cost AS (
    select entry_id,
           sum(abs(quantity) * coalesce(unit_cost, average_cost))/sum(abs(quantity)) as posting_avg_unit_cost
    from new_postings
    join account_average_cost using (account_id)
    where quantity < 0
    group by entry_id
  ),
  account_credit_avg_unit_cost AS (
    select account_id,
           sum(quantity) as credit_quantity,
           sum(quantity * posting_avg_unit_cost) / sum(quantity) as credit_avg_cost
    from new_postings
    join new_postings_debit_avg_unit_cost using (entry_id)
    where quantity > 0
    group by account_id
  ),
  account_credit_avg_cost AS (
    select account_id,
           ((credit_quantity * credit_avg_cost) + (quantity * average_cost))/(credit_quantity+quantity) as new_account_avg_cost
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
