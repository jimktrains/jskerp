set search_path TO inventory, public;

select unit_of_measure_id as item_uom
from unit_of_measure
where name = 'item' \gset

select unit_of_measure_id as yards_uom
from unit_of_measure
where name = 'yards' \gset

\echo Received 100 THING1 @ $10/unit and 25 WIDGET2 @ $10/unit

insert into journal default values returning entry_id \gset
insert into posting (entry_id, account_id, sku, quantity, measure, unit_of_measure_id, unit_cost) values
(:entry_id, 1, 'THING1', -100, 1, :item_uom, 10),
(:entry_id, 2, 'THING1',  100, 1, :item_uom, null),
(:entry_id, 7, 'WIDGET2', -25, 40, :yards_uom, 25),
(:entry_id, 8, 'WIDGET2',  25, 40, :yards_uom, null);

\echo Averae Costs
select account_id, quantity, average_cost
from account_average_cost
join account using (account_id)
order by account_id;

\echo FIFO Cost
select account_id, entry_id, quantity, measure, unit_cost
from account_fifo_cost
order by account_id, entry_id;

\echo Received 100 THING1 @ $15/unit
insert into journal default values returning entry_id \gset
insert into posting (entry_id, account_id, sku, quantity, measure, unit_of_measure_id, unit_cost) values
(:entry_id, 1, 'THING1', -100, 1, :item_uom, 15),
(:entry_id, 2, 'THING1',  100, 1, :item_uom, null);

\echo Averae Costs
select account_id, quantity, average_cost
from account_average_cost
join account using (account_id)
order by account_id;

\echo FIFO Cost
select account_id, entry_id, quantity, measure, unit_cost
from account_fifo_cost
order by account_id, entry_id;

\echo Stocked 50 THING1s
insert into journal default values returning entry_id \gset
insert into posting (entry_id, account_id, sku, quantity, measure, unit_of_measure_id) values
(:entry_id, 2, 'THING1', -50, 1, :item_uom),
(:entry_id, 3, 'THING1',  50, 1, :item_uom);

\echo Averae Costs
select account_id, quantity, average_cost
from account_average_cost
join account using (account_id)
order by account_id;

\echo FIFO Cost
select account_id, entry_id, quantity, measure, unit_cost
from account_fifo_cost
order by account_id, entry_id;

\echo Receive 100 THING1 @ $13/unit
insert into journal default values returning entry_id \gset
insert into posting (entry_id, account_id, sku, quantity, measure, unit_of_measure_id, unit_cost) values
(:entry_id, 1, 'THING1', -100, 1, :item_uom, 13),
(:entry_id, 2, 'THING1',  100, 1, :item_uom, null);

\echo Averae Costs
select account_id, quantity, average_cost
from account_average_cost
join account using (account_id)
order by account_id;

\echo FIFO Cost
select account_id, entry_id, quantity, measure, unit_cost
from account_fifo_cost
order by account_id, entry_id;

\echo Stocked another 50 THING1s
insert into journal default values returning entry_id \gset
insert into posting (entry_id, account_id, sku, quantity, measure, unit_of_measure_id) values
(:entry_id, 2, 'THING1', -50, 1, :item_uom),
(:entry_id, 3, 'THING1',  50, 1, :item_uom);

\echo Averae Costs
select account_id, quantity, average_cost
from account_average_cost
join account using (account_id)
order by account_id;

\echo FIFO Cost
select account_id, entry_id, quantity, measure, unit_cost
from account_fifo_cost
order by account_id, entry_id;

\echo Commited 12 THING1 to fulfilling an order
insert into journal default values returning entry_id \gset
insert into posting (entry_id, account_id, sku, quantity, measure, unit_of_measure_id) values
(:entry_id, 3, 'THING1', -12, 1, :item_uom),
(:entry_id, 4, 'THING1',  12, 1, :item_uom);

\echo Averae Costs
select account_id, quantity, average_cost
from account_average_cost
join account using (account_id)
order by account_id;

\echo FIFO Cost
select account_id, entry_id, quantity, measure, unit_cost
from account_fifo_cost
order by account_id, entry_id;

\echo Picked 2 THING1 into a shipping container
insert into journal default values returning entry_id \gset
insert into posting (entry_id, account_id, sku, quantity, measure, unit_of_measure_id) values
(:entry_id, 4, 'THING1', -2, 1, :item_uom),
(:entry_id, 5, 'THING1',  2, 1, :item_uom);

\echo Averae Costs
select account_id, quantity, average_cost
from account_average_cost
join account using (account_id)
order by account_id;

\echo FIFO Cost
select account_id, entry_id, quantity, measure, unit_cost
from account_fifo_cost
order by account_id, entry_id;

\echo Shipped those 2 widgets
insert into journal default values returning entry_id \gset
insert into posting (entry_id, account_id, sku, quantity, measure, unit_of_measure_id) values
(:entry_id, 5, 'THING1', -2, 1, :item_uom),
(:entry_id, 6, 'THING1',  2, 1, :item_uom);

\echo Averae Costs
select account_id, quantity, average_cost
from account_average_cost
join account using (account_id)
order by account_id;

\echo FIFO Cost
select account_id, entry_id, quantity, measure, unit_cost
from account_fifo_cost
order by account_id, entry_id;

\echo Commit another 12 THING1 to fulfilling another order
\echo This posting is not balance and will error

\set old_error_stop :ON_ERROR_STOP
\set ON_ERROR_STOP 0

insert into journal default values returning entry_id \gset
insert into posting (entry_id, account_id, sku, quantity, measure, unit_of_measure_id) values
(:entry_id, 3, 'THING1', -12, 1, :item_uom),
(:entry_id, 4, 'THING1',  10, 1, :item_uom);

\set ON_ERROR_STOP :old_error_stop

\echo Averae Costs
select account_id, quantity, average_cost
from account_average_cost
join account using (account_id)
order by account_id;

\echo FIFO Cost
select account_id, entry_id, quantity, measure, unit_cost
from account_fifo_cost
order by account_id, entry_id;

\echo Moving WIDGET2 5@1.5yds from 8 to 9
insert into journal default values returning entry_id \gset
insert into posting (entry_id, account_id, sku, quantity, measure, unit_of_measure_id) values
(:entry_id, 8, 'WIDGET2', -5, 1.5, :yards_uom),
(:entry_id, 9, 'WIDGET2', 5, 1.5, :yards_uom);

\echo Averae Costs
select account_id, quantity, average_cost
from account_average_cost
join account using (account_id)
order by account_id;

\echo FIFO Cost
select account_id, entry_id, quantity, measure, unit_cost
from account_fifo_cost
order by account_id, entry_id;

\set old_error_stop :ON_ERROR_STOP
\set ON_ERROR_STOP 0

\echo Moving WIDGET2 25@40yds from 8 to 10
\echo This will error because we do not have enough
insert into journal default values returning entry_id \gset
insert into posting (entry_id, account_id, sku, quantity, measure, unit_of_measure_id) values
(:entry_id, 8, 'WIDGET2', -25, 40, :yards_uom),
(:entry_id, 10, 'WIDGET2', 25, 40, :yards_uom);

\set ON_ERROR_STOP :old_error_stop

\echo Averae Costs
select account_id, quantity, average_cost
from account_average_cost
join account using (account_id)
order by account_id;

\echo FIFO Cost
select account_id, entry_id, quantity, measure, unit_cost
from account_fifo_cost
order by account_id, entry_id;
