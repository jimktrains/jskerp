# pgerp
An ERP system using PostgreSQL.  Starting as a test of transition tables,
as such there is a consicous absence of additional indices and foreign keys.

# Test

```sql
-- We should create accounts for all accounts, but for right
-- now this is all we need.
insert into account (item_id, account_type, amount) values
(1, 'inventory', 3),
(1, 'committed', 0);
select * from account;
--  account_id | item_id | account_type | amount | description
-- ------------+---------+--------------+--------+-------------
--           1 |       1 | inventory    |      3 |
--           2 |       1 | committed    |      0 |
-- (2 rows)


-- Place an order for 2 of item 1.
insert into order_item (order_id, item_id) values
(1, 1),
(1, 1);


-- See that the items have been commited to.
select * from order_item;
--  order_item_id | item_id | order_id |  status
-- ---------------+---------+----------+-----------
--              1 |       1 |        1 | committed
--              2 |       1 |        1 | committed
-- (2 rows)

-- See that it's decremented from the inventory account.
select * from account;
--  account_id | item_id | account_type | amount | description
-- ------------+---------+--------------+--------+-------------
--           1 |       1 | inventory    |      1 |
--           2 |       1 | committed    |      2 |
-- (2 rows)

-- Place another order for 2 of item 1.
insert into order_item (order_id, item_id) values
(2, 1),
(2, 1);

-- See that items have _not_ been commited since there isn't enough to
-- fullfil the order.
select * from order_item;
--  order_item_id | item_id | order_id |  status
-- ---------------+---------+----------+-----------
--              1 |       1 |        1 | committed
--              2 |       1 |        1 | committed
--              3 |       1 |        2 | ordered
--              4 |       1 |        2 | ordered
-- (4 rows)

-- See that the inventory has not been decremented.
select * from account;
--  account_id | item_id | account_type | amount | description
-- ------------+---------+--------------+--------+-------------
--           1 |       1 | inventory    |      1 |
--           2 |       1 | committed    |      2 |
-- (2 rows)

-- Place another order 2 orders for 1 of item 1.
insert into order_item (order_id, item_id) values
(3, 1),
(4, 1);

-- See that items for 3 have been and 4 have _not_ been commited since there
-- isn't enough to fullfil the order.
select * from order_item;
--  order_item_id | item_id | order_id |  status
-- ---------------+---------+----------+-----------
--              1 |       1 |        1 | committed
--              2 |       1 |        1 | committed
--              3 |       1 |        2 | ordered
--              4 |       1 |        2 | ordered
--              6 |       1 |        4 | ordered
--              5 |       1 |        3 | committed
-- (6 rows)



-- See that the inventory has not been decremented for 4.
select * from account;
--  account_id | item_id | account_type | amount | description
-- ------------+---------+--------------+--------+-------------
--           1 |       1 | inventory    |      0 |
--           2 |       1 | committed    |      3 |
-- (2 rows)
```


Version 2
---------

I'm trying to pare down tables and place functionality in seperate files 
to make editing easier.
