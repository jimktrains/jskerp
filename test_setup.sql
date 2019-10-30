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

insert into unit_of_measure (name, incremental, divisible, combinable) values
('item', 1, false, false)
returning unit_of_measure_id as item_uom
\gset

insert into unit_of_measure (name, incremental, divisible, combinable) values
('yards', 0.25, true, false)
returning unit_of_measure_id as yards_uom
\gset

insert into item (sku, unit_of_measure_id) values 
('THING1', :item_uom),
('WIDGET2', :yards_uom);

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
(account_id , location_id , account_type_id , sku       , quantity, measure, unit_of_measure_id)
values
(1          , 1           , 'supplied'      , 'THING1'  , 0, 0, :item_uom),
(2          , 2           , 'received'      , 'THING1'  , 0, 0, :item_uom),
(3          , 3           , 'stocked'       , 'THING1'  , 0, 0, :item_uom),
(4          , 3           , 'commited'      , 'THING1'  , 0, 0, :item_uom),
(5          , 4           , 'commited'      , 'THING1'  , 0, 0, :item_uom),
(6          , 4           , 'shipped'       , 'THING1'  , 0, 0, :item_uom),
(7          , 1           , 'supplied'      , 'WIDGET2' , 0, 0, :yards_uom),
(8          , 2           , 'received'      , 'WIDGET2' , 0, 0, :yards_uom),
(9          , 3           , 'stocked'       , 'WIDGET2' , 0, 0, :yards_uom),
(10         , 3           , 'commited'      , 'WIDGET2' , 0, 0, :yards_uom),
(11         , 4           , 'commited'      , 'WIDGET2' , 0, 0, :yards_uom),
(12         , 4           , 'shipped'       , 'WIDGET2' , 0, 0, :yards_uom)
;
