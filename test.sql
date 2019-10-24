SET search_path TO inventory, public;

insert into item (sku) values ('THING1'), ('WIDGET2');

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

insert into account_average_cost
(account_id)
values
(1),
(2),
(3),
(4),
(5),
(6)
;

select * from location;
select * from account;
select * from posting;
select * from account_average_cost;

\echo Received 100 Widgets

insert into journal default values returning entry_id \gset
insert into posting (entry_id, account_id, sku, quantity, unit_cost) values
(:entry_id, 1, 'THING1', -100, 10),
(:entry_id, 2, 'THING1',  100, null),
(:entry_id, 7, 'WIDGET2', -25, 10),
(:entry_id, 8, 'WIDGET2',  25, null);

select account_id, quantity, average_cost  from account_average_cost join account using (account_id);

insert into journal default values returning entry_id \gset
insert into posting (entry_id, account_id, sku, quantity, unit_cost) values
(:entry_id, 1, 'THING1', -100, 15),
(:entry_id, 2, 'THING1',  100, null);

select account_id, quantity, average_cost  from account_average_cost join account using (account_id);

\echo Stocked 50 of those widgets
insert into journal default values returning entry_id \gset
insert into posting (entry_id, account_id, sku, quantity) values
(:entry_id, 2, 'THING1', -50),
(:entry_id, 3, 'THING1',  50);

select account_id, quantity, average_cost  from account_average_cost join account using (account_id);

\echo Receive 100 more
insert into journal default values returning entry_id \gset
insert into posting (entry_id, account_id, sku, quantity, unit_cost) values
(:entry_id, 1, 'THING1', -100, 13),
(:entry_id, 2, 'THING1',  100, null);

select account_id, quantity, average_cost  from account_average_cost join account using (account_id);

\echo Stocked another 50 of those widgets
insert into journal default values returning entry_id \gset
insert into posting (entry_id, account_id, sku, quantity) values
(:entry_id, 2, 'THING1', -50),
(:entry_id, 3, 'THING1',  50);

select account_id, quantity, average_cost  from account_average_cost join account using (account_id);

\echo Commited 12 of those widgets to fulfilling an order
insert into journal default values returning entry_id \gset
insert into posting (entry_id, account_id, sku, quantity) values
(:entry_id, 3, 'THING1', -12),
(:entry_id, 4, 'THING1',  12);

select account_id, quantity, average_cost  from account_average_cost join account using (account_id);

\echo Picked 2 widgets into a shipping container
insert into journal default values returning entry_id \gset
insert into posting (entry_id, account_id, sku, quantity) values
(:entry_id, 4, 'THING1', -2),
(:entry_id, 5, 'THING1',  2);

select account_id, quantity, average_cost  from account_average_cost join account using (account_id);

\echo Shipped the widgets
insert into journal default values returning entry_id \gset
insert into posting (entry_id, account_id, sku, quantity) values
(:entry_id, 5, 'THING1', -2),
(:entry_id, 6, 'THING1',  2);

select account_id, quantity, average_cost  from account_average_cost join account using (account_id);

\echo Commit another 12 of those widgets to fulfilling an order
\echo This posting is not balance and will error
insert into journal default values returning entry_id \gset
insert into posting (entry_id, account_id, sku, quantity) values
(:entry_id, 3, 'THING1', -12),
(:entry_id, 4, 'THING1',  10);

select account_id, quantity, average_cost  from account_average_cost join account using (account_id);
