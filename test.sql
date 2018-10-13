SET search_path TO inventory, public;

insert into item (sku) values ('THING1');

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
(account_id , location_id , account_type_id , sku      , quantity)
values
(1          , 1           , 'supplied'      , 'THING1' , 0)        ,
(2          , 2           , 'received'      , 'THING1' , 0)        ,
(3          , 3           , 'stocked'       , 'THING1' , 0)        ,
(4          , 3           , 'commited'      , 'THING1' , 0)        ,
(5          , 4           , 'commited'      , 'THING1' , 0)        ,
(6          , 4           , 'shipped'       , 'THING1' , 0)
;

select * from location;
select * from posting;

\echo Received 100 Widgets

insert into journal (entry_id) values (1);
insert into posting (entry_id, account_id, quantity) values
(1, 1, -100),
(1, 2,  100);

select * from location;
select * from posting;

\echo Stocked 50 of those widgets
insert into journal (entry_id) values (2);
insert into posting (entry_id, account_id, quantity) values
(2, 2, -50),
(2, 3,  50);

select * from location;
select * from posting;

\echo Commited 12 of those widgets to fulfilling an order
insert into journal (entry_id) values (3);
insert into posting (entry_id, account_id, quantity) values
(3, 3, -12),
(3, 4,  12);

select * from location;
select * from posting;

\echo Picked 2 widgets into a shipping container
insert into journal (entry_id) values (4);
insert into posting (entry_id, account_id, quantity) values
(4, 4, -2),
(4, 5,  2);

select * from location;
select * from posting;

\echo Shipped the widgets
insert into journal (entry_id) values (5);
insert into posting (entry_id, account_id, quantity) values
(5, 5, -2),
(5, 6,  2);

select * from location;
select * from posting;

\echo Commit another 12 of those widgets to fulfilling an order
\echo This posting is not balance and will error
insert into journal (entry_id) values (6);
insert into posting (entry_id, account_id, quantity) values
(6, 3, -12),
(6, 4,  10);


insert into purchase_order_item (entry_id, unit_cost)
values (1, 1);

select * from account;
select * from purchase_order_item;

\echo Received 20 Widgets

insert into journal (entry_id) values (7);
insert into posting (entry_id, account_id, quantity) values
(7, 1, -20),
(7, 5, 20);

select * from location;
select * from posting;

insert into purchase_order_item (entry_id, unit_cost)
values (7, 5);

select * from purchase_order_item;
