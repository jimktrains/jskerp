-- We should create accounts for all accounts, but for right
-- now this is all we need.
insert into account (item_id, account_type, amount) values 
(1, 'inventory', 3),
(1, 'committed', 0);
select * from account;

-- Place an order for 2 of item 1.
insert into order_item (order_id, item_id) values
(1, 1),
(1, 1);

-- See that the items have been commited to.
select * from order_item;
-- See that it's decremented from the inventory account.
select * from account;

-- Place another order for 2 of item 1.
insert into order_item (order_id, item_id) values
(2, 1),
(2, 1);

-- See that items have _not_ been commited since there isn't enough to
-- fullfil the order.
select * from order_item;
-- See that the inventory has not been decremented.
select * from account;
