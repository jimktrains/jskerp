SET search_path TO inventory, public;

insert into item (sku) values ('THING1');

insert into location 
(location_id , location_type_id , location_lpn , account_type_id , sku      , quantity)
values
(1           , 'supplier'       , 'megacorp'   , 'supplied'      , 'THING1' , 0)        ,
(2           , 'receiving'      , 'megacorp'   , 'received'      , 'THING1' , 0)        ,
(3           , 'stock'          , 'A-B-C-D'    , 'stocked'       , 'THING1' , 0)        ,
(4           , 'stock'          , 'A-B-C-D'    , 'commited'      , 'THING1' , 0)        ,
(5           , 'package'        , '12345'      , 'commited'      , 'THING1' , 0)        ,
(6           , 'package'        , '12345'      , 'shipped'       , 'THING1' , 0)
;

select * from location;
select * from posting;

\echo Received 100 Widgets

insert into journal (entry_id) values (1);
insert into posting (entry_id, location_id, quantity) values
(1, 1, -100),
(1, 2,  100);

select * from location;
select * from posting;

\echo Stocked 50 of those widgets
insert into journal (entry_id) values (2);
insert into posting (entry_id, location_id, quantity) values
(2, 2, -50),
(2, 3,  50);

select * from location;
select * from posting;

\echo Commited 12 of those widgets to fulfilling an order
insert into journal (entry_id) values (3);
insert into posting (entry_id, location_id, quantity) values
(3, 3, -12),
(3, 4,  12);

select * from location;
select * from posting;

\echo Picked 2 widgets into a shipping container
insert into journal (entry_id) values (4);
insert into posting (entry_id, location_id, quantity) values
(4, 4, -2),
(4, 5,  2);

select * from location;
select * from posting;

\echo Shipped the widgets
insert into journal (entry_id) values (5);
insert into posting (entry_id, location_id, quantity) values
(5, 5, -2),
(5, 6,  2);

select * from location;
select * from posting;

\echo Commit another 12 of those widgets to fulfilling an order
\echo This posting is not balance and will error
insert into journal (entry_id) values (6);
insert into posting (entry_id, location_id, quantity) values
(6, 3, -12),
(6, 4,  10);

select * from location;
select * from posting;
