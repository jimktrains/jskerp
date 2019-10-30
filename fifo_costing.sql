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
  account_fifo_cost_id bigserial primary key,
  account_id bigint references account(account_id) not null,
  sku text not null references item,
  entry_id bigint references journal(entry_id) not null,
  quantity numeric(10,4) not null check(quantity >= 0),
  measure numeric(10,4) not null check(measure > 0),
  unit_of_measure_id bigint not null references unit_of_measure,
  unit_cost numeric(10,4) not null,
  foreign key (account_id, sku, unit_of_measure_id) references account (account_id, sku, unit_of_measure_id)
);

create function function_update_fifo_cost()
returns trigger
as $$
declare
  credits cursor for select * from credit_sink;
  credit posting%rowtype;
  debit record;
  debit_count int;
  ratio int;
  rem int;
  debit_quantity_moved int;
  ttl_credit_quantity_moved int;
  remaining_measure numeric(10,4);
  debits cursor (forcredit posting%rowtype) for
    select account_fifo_cost.account_fifo_cost_id,
           account_fifo_cost.account_id,
           account_fifo_cost.sku,
           account_fifo_cost.entry_id,
           account_fifo_cost.quantity,
           account_fifo_cost.measure,
           account_fifo_cost.unit_of_measure_id,
           account_fifo_cost.unit_cost,
           combinable,
           divisible
    from account_fifo_cost
    join new_postings using (account_id, unit_of_measure_id)
    join unit_of_measure using (unit_of_measure_id)
    where new_postings.quantity < 0 and account_fifo_cost.sku = forcredit.sku
      and (
        (combinable and divisible)
        or
        (combinable and account_fifo_cost.measure <= forcredit.measure)
        or
        (divisible and account_fifo_cost.measure >= forcredit.measure)
        or
        (not(combinable) and not(divisible) and account_fifo_cost.measure = forcredit.measure)
      )
    order by account_fifo_cost.entry_id asc
    ;
begin
  insert into account_fifo_cost
  (account_id, entry_id, sku, quantity,  measure, unit_of_measure_id, unit_cost)
  select account_id,
         entry_id,
         sku,
         -- Normalize quantity and measure for items that are
         -- combinable and divisible at will. This simplifies movements
         -- considerably.
         case
           when combinable and divisible then -quantity * measure / incremental
           else -quantity
         end as quantity,
         case
           when combinable and divisible then incremental
           else measure
         end as measure,
         unit_of_measure_id,
         unit_cost
  from new_postings
  join unit_of_measure using (unit_of_measure_id)
  where quantity < 0
    and unit_cost is not null;


  create temporary table debit_source as (
    select account_fifo_cost.account_fifo_cost_id,
           account_fifo_cost.sku,
           account_fifo_cost.entry_id,
           account_fifo_cost.quantity,
           account_fifo_cost.measure,
           account_fifo_cost.unit_of_measure_id,
           account_fifo_cost.unit_cost,
           combinable,
           divisible,
           incremental
    from account_fifo_cost
    join new_postings using (account_id, unit_of_measure_id)
    join unit_of_measure using (unit_of_measure_id)
    where new_postings.quantity < 0
  );

  create temporary table credit_sink as (
    select *
    from new_postings
    where new_postings.quantity > 0
  );

  for credit in credits loop
    debit_count := 0;


    for debit in debits(credit) loop
      debit_count = debit_count + 1;

      -- Normalize quantity and measure for items that are
      -- combinable and divisible at will. This simplifies movements
      -- considerably.
      --
      -- Right now the credits and debits need to have the same unit of
      -- measurement, so this is OK. It's also idempotent in that furter
      -- applications have no effect because measure = incremental at that
      -- point.
      if debit.combinable and debit.divisible then
        credit.quantity = credit.quantity * debit.measure / debit.incremental;
        credit.measure = incremental;
      end if;

      case
        -- Items that are combinable and divisible are items like dirt, gravel,
        -- or deli cheese. We can split a pile and then combine splits from
        -- different piles into new piles. These are all normalized to the
        -- same measure unit.
        --
        -- Otherwise, if the debit and credit have the same measure, we
        -- can simplify the calculation because there is no need to
        -- split an item to obtain the correct measure.
        when debit.measure = credit.measure then
          debit_quantity_moved := least(debit.quantity, credit.quantity);
          ttl_credit_quantity_moved := debit_quantity_moved;
          credit.quantity = credit.quantity - ttl_credit_quantity_moved;

          update account_fifo_cost
          set quantity = quantity - debit_quantity_moved
          where account_fifo_cost_id = debit.account_fifo_cost_id;

          insert into account_fifo_cost
          (account_id, sku, entry_id, quantity, measure, unit_of_measure_id, unit_cost)
          values
          (credit.account_id, credit.sku, credit.entry_id, ttl_credit_quantity_moved, credit.measure, credit.unit_of_measure_id, debit.unit_cost)
          ;

        -- These are things like ?
        when (debit.combinable and debit.measure <= credit.measure) then

        -- These are items like fabric. We can split fabric into many cuts, but
        -- we cannot recombine many cuts into a new cut.
        when (debit.divisible and debit.measure >= credit.measure) then
          -- ex 1: debit=3@5yd credit=5@2yd
          -- ex 2: debit=25@40yd credit=25@20yd

          -- ex 1: floor(5 debit measures / debit item /2 credit measure / credit item) = 2 credit items per debit item
          -- ex 2: floor(40/20) = 2

          -- Floor because since this isn't combinable we can't take
          -- a partial amount from this debit item and apply it to another
          -- credit item such that the partial amount doesn't fulfil the
          -- measure of the credit item.
          ratio := floor(debit.measure / credit.measure);

          -- ex 1: floor(4 credit items/ 2 credit items / debit item) = 2 debit items
          -- ex 2: floor(25 / 2) = 12
          debit_quantity_moved := floor(credit.quantity / ratio);

          -- ex 1: least(2, 10) = 2
          -- ex 2: least(12, 25) = 12
          debit_quantity_moved := least(debit_quantity_moved, debit.quantity);

          -- ex 1: ((5 - (2 * 2)) = 1)yd
          -- ex 2: 40 - (20 * 2) = 0yd
          remaining_measure :=  debit.measure - (credit.measure * ratio);

          -- ex 1: insert 2@1yd
          -- ex 2: don't insert
          if remaining_measure > 0 then
            insert into account_fifo_cost
            (account_id, sku, entry_id, quantity, measure, unit_of_measure_id, unit_cost)
            values
            (debit.account_id, debit.sku, debit.entry_id, debit_quantity_moved, remaining_measure, debit.unit_of_measure_id, debit.unit_cost)
            ;
          end if;

          -- ex 1: 2 * 2 = 4
          -- ex 2: 12 * 2 = 24
          ttl_credit_quantity_moved := debit_quantity_moved * ratio;

          -- Check if there's anough of the debits to satisfy any credits
          -- This should only happen after all of the ratio-increment movments
          -- have been done.
          if debit.quantity > debit_quantity_moved and credit.quantity > ttl_credit_quantity_moved and (credit.quantity - ttl_credit_quantity_moved) < ratio then
            -- Since there can't be any more than would fit in a since debit item
            -- Subtract one more from the quantity.
            debit_quantity_moved := debit_quantity_moved + 1;

            -- Subtract the measure used in this last cut from the debit.
            --
            -- ex 1: 5 debit measure - (2 credit measure / credit item * 1 credit item / credit measure) = 3 debit meausres
            -- ex 2: 40 - (20 * (25 - 24)) = 20
            remaining_measure :=  debit.measure - (credit.measure * (credit.quantity - ttl_credit_quantity_moved));

            if remaining_measure > 0 then
              insert into account_fifo_cost
              (account_id, sku, entry_id, quantity, measure, unit_of_measure_id, unit_cost)
              values
              (debit.account_id, debit.sku, debit.entry_id, 1, remaining_measure, debit.unit_of_measure_id, debit.unit_cost)
              ;
            end if;
            -- If we're here, we're finishing off the credits.
            ttl_credit_quantity_moved := credit.quantity;
          end if;

          -- ex 1: 2 debit items * 2 credit items per debit item = 4 credit items
          credit.quantity := credit.quantity - ttl_credit_quantity_moved;

          -- ex 1: subtract 2@5yd
          update account_fifo_cost
          set quantity = quantity - debit_quantity_moved
          where account_fifo_cost_id = debit.account_fifo_cost_id;


          insert into account_fifo_cost
          (account_id, sku, entry_id, quantity, measure, unit_of_measure_id, unit_cost)
          values
          (credit.account_id, credit.sku, credit.entry_id, ttl_credit_quantity_moved, credit.measure, credit.unit_of_measure_id, debit.unit_cost)
          ;

        -- These are things like whole widgets. We cannot combine or divide
        -- them.
        --
        -- TODO: Right now we can only move between them if their measures are
        -- the same, although that's not strictly true and will probably change
        -- later. For instance, if I order 2 widgets, and I have a bin where
        -- each item is 2 measures of a widget, that should be able to fulfill
        -- a need for 2 widets.
        when (not(debit.combinable) and not(debit.divisible)) then
      end case;
    end loop;
    if credit.quantity <> 0 then
      raise 'Unable to fulfil posting_id=% for % qty=%@%', credit.posting_id, credit.sku, credit.quantity, credit.measure;
    end if;
  end loop;

  -- Clean up empty accounts so that we're not littering our table.
  delete from account_fifo_cost where quantity = 0;

  with agg as (
    select account_id, 
           entry_id,
           sku,
           unit_cost,
           measure,
           unit_of_measure_id,
           sum(quantity) as quantity
    from account_fifo_cost
    where entry_id in (select distinct entry_id from new_postings)
    group by account_id,
             entry_id,
             sku,
             unit_cost,
             measure,
             unit_of_measure_id
  ),
  del as (
    delete
    from account_fifo_cost
    using agg
    where agg.account_id = account_fifo_cost.account_id
      and agg.entry_id = account_fifo_cost.entry_id
      and agg.sku = account_fifo_cost.sku
      and agg.unit_cost = account_fifo_cost.unit_cost
      and agg.measure = account_fifo_cost.measure
      and agg.unit_of_measure_id = account_fifo_cost.unit_of_measure_id
  )
  insert into account_fifo_cost
  (account_id, entry_id, sku, unit_cost, measure, unit_of_measure_id, quantity)
  select account_id,
         entry_id,
         sku,
         unit_cost,
         measure,
         unit_of_measure_id,
         quantity
  from agg;

  -- Clean up after ourselves, although I'm not super fond of having to
  -- do this in the first place.
  drop table debit_source;
  drop table credit_sink;

  return new;
end;
$$ language plpgsql;

create trigger trigger_update_fifo_cost
after insert
on posting
referencing new table as new_postings
for each statement
execute procedure function_update_fifo_cost();

