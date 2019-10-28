set search_path TO inventory, public;

insert into account_type (account_type_id) values
('supplied'),
('received'),
('stocked'),
('commited'),
('shipped')
;
insert into location_type (location_type_id) values
('supplier'),
('receiving'),
('stock'),
('picking'),
('assembly'),
('package')
;

insert into unit_of_measure (name, incremental) values
('item', 1)
returning unit_of_measure_id as item_uom
\gset

insert into unit_of_measure (name, incremental) values
('yards', 0.25)
returning unit_of_measure_id as yards_uom
\gset

insert into item (sku, unit_of_measure_id) values 
('THING1', item_uom),
('WIDGET2', yards_uom);

insert into location 
(location_id , location_type_id , location_lpn) 
values
(1           , 'supplier'       , 'megacorp'   ) ,
(2           , 'receiving'      , 'Shipper.54321'   ) ,
(3           , 'stock'          , 'A-B-C-D'    ) ,
(4           , 'package'        , 'Shipper.12345'      ),
(5           , 'receiving'      , 'Shipper.98765'   )
;

insert into account
(account_id , location_id , account_type_id , sku       , quantity)
values
(1          , 1           , 'supplied'      , 'THING1'  , 0),
(2          , 2           , 'received'      , 'THING1'  , 0),
(3          , 3           , 'stocked'       , 'THING1'  , 0),
(4          , 3           , 'commited'      , 'THING1'  , 0),
(5          , 4           , 'commited'      , 'THING1'  , 0),
(6          , 4           , 'shipped'       , 'THING1'  , 0),
(7          , 1           , 'supplied'      , 'WIDGET2' , 0),
(8          , 2           , 'received'      , 'WIDGET2' , 0),
(9          , 3           , 'stocked'       , 'WIDGET2' , 0),
(10         , 3           , 'commited'      , 'WIDGET2' , 0),
(11         , 4           , 'commited'      , 'WIDGET2' , 0),
(12         , 4           , 'shipped'       , 'WIDGET2' , 0)
;

select * from location;
select * from account;
select * from posting;
select * from account_average_cost;

\echo Received 100 THING1 @ $10/unit and 25 WIDGET2 @ $10/unit

insert into journal default values returning entry_id \gset
insert into posting (entry_id, account_id, sku, quantity, measure, unit_of_measure_id, unit_cost) values
(:entry_id, 1, 'THING1', -100, 1, item_uom, 10),
(:entry_id, 2, 'THING1',  100, 1, item_uom, null),
(:entry_id, 7, 'WIDGET2', -25, 40, yards_uom, 10),
(:entry_id, 8, 'WIDGET2',  25, 40, yards_uom, null);

select account_id, quantity, average_cost
from account_average_cost
join account using (account_id)
order by account_id;

select account_id, entry_id, quantity, unit_cost
from account_fifo_cost
order by account_id, entry_id;

\echo Received 100 THING1 @ $15/unit
insert into journal default values returning entry_id \gset
insert into posting (entry_id, account_id, sku, quantity, unit_cost) values
(:entry_id, 1, 'THING1', -100, 15),
(:entry_id, 2, 'THING1',  100, null);

select account_id, quantity, average_cost
from account_average_cost
join account using (account_id)
order by account_id;

select account_id, entry_id, quantity, unit_cost
from account_fifo_cost
order by account_id, entry_id;

\echo Stocked 50 THING1s
insert into journal default values returning entry_id \gset
insert into posting (entry_id, account_id, sku, quantity) values
(:entry_id, 2, 'THING1', -50),
(:entry_id, 3, 'THING1',  50);

select account_id, quantity, average_cost
from account_average_cost
join account using (account_id)
order by account_id;

select account_id, entry_id, quantity, unit_cost
from account_fifo_cost
order by account_id, entry_id;

\echo Receive 100 THING1 @ $13/unit
insert into journal default values returning entry_id \gset
insert into posting (entry_id, account_id, sku, quantity, unit_cost) values
(:entry_id, 1, 'THING1', -100, 13),
(:entry_id, 2, 'THING1',  100, null);

select account_id, quantity, average_cost
from account_average_cost
join account using (account_id)
order by account_id;

select account_id, entry_id, quantity, unit_cost
from account_fifo_cost
order by account_id, entry_id;

\echo Stocked another 50 THING1s
insert into journal default values returning entry_id \gset
insert into posting (entry_id, account_id, sku, quantity) values
(:entry_id, 2, 'THING1', -50),
(:entry_id, 3, 'THING1',  50);

select account_id, quantity, average_cost
from account_average_cost
join account using (account_id)
order by account_id;

select account_id, entry_id, quantity, unit_cost
from account_fifo_cost
order by account_id, entry_id;

\echo Commited 12 THING1 to fulfilling an order
insert into journal default values returning entry_id \gset
insert into posting (entry_id, account_id, sku, quantity) values
(:entry_id, 3, 'THING1', -12),
(:entry_id, 4, 'THING1',  12);

select account_id, quantity, average_cost
from account_average_cost
join account using (account_id)
order by account_id;

select account_id, entry_id, quantity, unit_cost
from account_fifo_cost
order by account_id, entry_id;

\echo Picked 2 THING1 into a shipping container
insert into journal default values returning entry_id \gset
insert into posting (entry_id, account_id, sku, quantity) values
(:entry_id, 4, 'THING1', -2),
(:entry_id, 5, 'THING1',  2);

select account_id, quantity, average_cost
from account_average_cost
join account using (account_id)
order by account_id;

select account_id, entry_id, quantity, unit_cost
from account_fifo_cost
order by account_id, entry_id;

\echo Shipped those 2 widgets
insert into journal default values returning entry_id \gset
insert into posting (entry_id, account_id, sku, quantity) values
(:entry_id, 5, 'THING1', -2),
(:entry_id, 6, 'THING1',  2);

select account_id, quantity, average_cost
from account_average_cost
join account using (account_id)
order by account_id;

select account_id, entry_id, quantity, unit_cost
from account_fifo_cost
order by account_id, entry_id;

\echo Commit another 12 THING1 to fulfilling another order
\echo This posting is not balance and will error
insert into journal default values returning entry_id \gset
insert into posting (entry_id, account_id, sku, quantity) values
(:entry_id, 3, 'THING1', -12),
(:entry_id, 4, 'THING1',  10);

select account_id, quantity, average_cost
from account_average_cost
join account using (account_id)
order by account_id;

select account_id, entry_id, quantity, unit_cost
from account_fifo_cost
order by account_id, entry_id;

