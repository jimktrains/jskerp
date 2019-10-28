SET search_path TO inventory, public;

-- FIFO Costing is done by keeping track of the cost and quantity of
-- items as they are moved around. When moved, the oldest cost for that
-- account is used and decremented.

-- In theory we could have a transaction (say transaction1) with
--   account1x10 @ $1 -> account3
--   account2x15 @ $2 -> account3
-- and then here in account3, we'd need to have
--   account3, transaction1, 10, $1
--   account3, transaction1, 15, $2
-- so, we shouldn't combine by price or entry.
create table account_fifo_cost (
  account_fifo_cost bigserial primary key,
  account_id bigint references account(account_id) not null,
  entry_id bigint references journal(entry_id) not null,
  quantity numeric(10,4) not null check(quantity >= 0),
  measure numeric(10,4) not null check(measure > 0),
  unit_of_measure_id bigint not null references unit_of_measure,
  divisible boolean not null,
  unit_cost numeric(10,4) not null
);

create or replace function function_update_fifo_cost ()
returns trigger
as $$
begin
  -- Add in any new costs from the debits.
  insert into account_fifo_cost
  (account_id, entry_id, quantity,  measure, unit_of_measure_id, divisible, unit_cost)
  select account_id, entry_id, -quantity,  measure, unit_of_measure_id, divisible, unit_cost
  from new_postings
  where quantity < 0 and unit_cost is not null;

  with recursive
  -- Computes how many items from each account are going to move.
  account_debit_quantity_needed as (
    select account_id, 
           sku,
           sum(-quantity) as quantity_needed
    from new_postings
    where quantity < 0
    group by account_id, sku
  ),
  -- Orders the debit source account costs by entry so that the oldest
  -- is used. Adds in sequential row numbers by sku.
  debit_source as (
    select sku,
           account_id as debit_account_id,
           entry_id as debit_entry_id,
           quantity as debit_quantity,
           measure as debit_measure,
           unit_of_measure_id as debit_unit_of_measure_id,
           divisible as debit_divsible,
           unit_cost as debit_unit_cost,
           row_number() over sku_w as m
    from (
      select account_id,
             entry_id,
             quantity,
             measure,
             unit_of_measure_id,
             divisible,
             unit_cost,
             sum(-quantity) over sku_w as debit_total_quantity,
             coalesce(sum(-quantity) over sku_m1_w, 0) as debit_prev_total_quantity
      from account_fifo_cost
      window sku_w as (partition by account_id order by account_id asc, entry_id asc, unit_cost asc rows between unbounded preceding and current row),
             sku_m1_w as (partition by account_id order by account_id asc, entry_id asc, unit_cost asc rows between unbounded preceding and 1 preceding)
    ) x
    join account_debit_quantity_needed using (account_id)
    where quantity_needed > debit_total_quantity 
       or quantity_needed between debit_prev_total_quantity and debit_total_quantity
    window sku_w as (partition by account_id order by account_id asc, entry_id asc, unit_cost asc rows between unbounded preceding and current row)
    order by sku, account_id, entry_id

  ),
  -- Orders the credit accounts (arbitraily). Adds in a sequential row
  -- number by sku.
  credit_sink as (
    select account_id as credit_account_id,
           entry_id as credit_entry_id,
           sku,
           quantity as credit_quantity,
           measure as credit_measure,
           unit_of_measure as credit_unit_of_measure,
           divisible as credit_divisble,
           row_number() over sku_w as n
    from new_postings
    where new_postings.quantity > 0
    window sku_w as (partition by sku order by sku, account_id, entry_id asc rows between unbounded preceding and current row)
    order by quantity, sku, account_id, entry_id
  ),
  -- Generates a movement table so that we know how many of each account
  -- at a cost moves into a credit account.

  -- 1. Using the sequential row numbers above, starting with the first
  --   credit and debit account for each sku.
  -- 2. Figure out how many credits and debits are consumed in the move and
  --   how many remain.
  -- 3. If there are items remaining in an account, don't move to the next
  --   account, otherwise move to the next account.
  -- 4. Get the next appropriate accounts and go to 2 or complete
  movement as (
    select sku,
           credit_account_id,
           credit_entry_id,
           credit_quantity,
           n,
           debit_account_id,
           debit_entry_id,
           debit_quantity,
           debit_unit_cost,
           m,
           quantity_moved,
           debit_quantity_remaining,
           credit_quantity_remaining,
           n + (credit_quantity_remaining = 0)::integer as next_n,
           m + (debit_quantity_remaining = 0)::integer as next_m
    from (
      select *,
             debit_quantity - quantity_moved as debit_quantity_remaining,
             credit_quantity - quantity_moved as credit_quantity_remaining
      from (
        select sku,
               credit_account_id,
               credit_entry_id,
               credit_quantity,
               n,
               debit_account_id,
               debit_entry_id,
               debit_quantity,
               debit_unit_cost,
               m,
               least(debit_quantity, credit_quantity) as quantity_moved
        from debit_source
        join credit_sink using (sku)
        where n = 1 and m = 1
      ) y
    ) x

    union all

    select sku,
           credit_account_id,
           credit_entry_id,
           credit_quantity,
           n,
           debit_account_id,
           debit_entry_id,
           debit_quantity,
           debit_unit_cost,
           m,
           -- this cast scares me because it means I've screwed something up
           -- somewhere.
           quantity_moved::numeric(10,4),
           debit_quantity_remaining,
           credit_quantity_remaining,
           n + (credit_quantity_remaining = 0)::integer as next_n,
           m + (debit_quantity_remaining = 0)::integer as next_m
    from (
      select sku,
             credit_account_id,
             credit_entry_id,
             credit_quantity,
             n,
             debit_account_id,
             debit_entry_id,
             debit_quantity,
             debit_unit_cost,
             m,
             quantity_moved,
             debit_quantity_remaining - quantity_moved as debit_quantity_remaining,
             credit_quantity_remaining - quantity_moved as credit_quantity_remaining
      from (
        select *,
               least(debit_quantity_remaining, credit_quantity_remaining) as quantity_moved             
        from (
          select sku,
                 credit_sink.credit_account_id,
                 credit_sink.credit_entry_id,
                 credit_sink.credit_quantity,
                 credit_sink.n,
                 debit_source.debit_account_id,
                 debit_source.debit_entry_id,
                 debit_source.debit_quantity,
                 debit_source.debit_unit_cost,
                 debit_source.m,

                 coalesce(nullif(debit_quantity_remaining, 0::numeric(10,4)), debit_source.debit_quantity) as debit_quantity_remaining,
                 coalesce(nullif(credit_quantity_remaining, 0::numeric(10,4)), credit_sink.credit_quantity) as credit_quantity_remaining
          from movement
          join debit_source using (sku)
          join credit_sink using (sku)
          where movement.next_n = credit_sink.n 
            and movement.next_m = debit_source.m
        ) z
      ) y
    ) x
  ),
  -- Combines all movements by debit account cost to make the update easier.
  total_debited as (
    select debit_account_id as account_id,
           debit_entry_id as entry_id,
           sum(quantity_moved) as quantity_moved,
           debit_unit_cost as unit_cost
    from movement
    group by debit_account_id, debit_entry_id, debit_unit_cost
  ),
  -- Combines all the movmenets by credit account and cost to make the
  -- insert easier.
  total_credited as (
    select credit_account_id as account_id,
           credit_entry_id as entry_id,
           sum(quantity_moved) as quantity_moved,
           debit_unit_cost as unit_cost
    from movement
    group by credit_account_id, credit_entry_id, debit_unit_cost
  ),
  -- Update the debits.
  update_debits_account_fifo_cost as (
    update account_fifo_cost
    set quantity = quantity - quantity_moved
    from total_debited
    where total_debited.account_id = account_fifo_cost.account_id
      and total_debited.entry_id = account_fifo_cost.entry_id
      and total_debited.unit_cost = account_fifo_cost.unit_cost 
  )
  -- Insert the credits.
  insert into account_fifo_cost
  (account_id, entry_id, quantity, unit_cost)
  select account_id, entry_id, quantity_moved, unit_cost
  from total_credited;

  -- Clean up the debit account costs that have no quantity in them.
  delete from account_fifo_cost
  where quantity = 0;

  return new;
end;
$$ language plpgsql;

create trigger trigger_update_fifo_cost
after insert
on posting
referencing new table as new_postings
for each statement
execute procedure function_update_fifo_cost();

