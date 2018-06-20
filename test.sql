insert into account (item_id, account_type, amount) values 
(1, 'inventory', 3),
(1, 'committed', 0);
select * from account;

insert into order_item (order_id, item_id) values
(1, 1),
(1, 1);

select * from order_item;
select * from account;

insert into order_item (order_id, item_id) values
(2, 1),
(2, 1);

select * from order_item;
select * from account;
