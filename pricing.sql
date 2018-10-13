drop view current_item_price;
drop table item_price;

create table item_price (
  sku text not null, -- references item,
  starts_at timestamptz,
  ends_at timestamptz,
  price decimal(5,2) not null,
  check((starts_at IS NULL) = (ends_at IS NULL)),
  unique (sku, starts_at, ends_at)
);

create view current_item_price as
select 
  distinct on (sku) sku, price
from item_price
where now() between 
  coalesce(starts_at, '1970-01-01 00:00Z'::timestamptz) 
  and
  coalesce(ends_at, '9999-12-31 23:59Z'::timestamptz)
order by sku, (ends_at - starts_at) asc nulls last
;

insert into item_price (sku, starts_at, ends_at, price) values
('THING1', null, null, 10)
;
select * from current_item_price;
--   sku   | price
-- --------+-------
--  THING1 | 10.00
-- (1 row)

insert into item_price (sku, starts_at, ends_at, price) values
('THING1', '2018-10-01', '2018-10-31', 8)
;
select * from current_item_price;
--   sku   | price
-- --------+-------
--  THING1 |  8.00
-- (1 row)

insert into item_price (sku, starts_at, ends_at, price) values
('THING1', '2018-10-01', '2018-10-09', 5)
;
select * from current_item_price;
--   sku   | price
-- --------+-------
--  THING1 |  8.00
-- (1 row)

insert into item_price (sku, starts_at, ends_at, price) values
('THING1', '2018-10-10', '2018-10-11', 7)
;
select * from current_item_price;
--   sku   | price
-- --------+-------
--  THING1 |  7.00
-- (1 row)
