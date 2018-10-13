SET search_path TO inventory, public;

-- create table purchase_order (
--   purchase_order_id bigserial primary key,
-- 
-- );

create table purchase_order_item (
  purchase_order_id bigserial primary key,
  unit_cost decimal(10,2) not null check (unit_cost >= 0),
  entry_id bigint,
  unique (purchase_order_id, entry_id)
);

-- create view account_average_cost as
-- with recursive movement_chain(from_account_id, to_account_id, quantity) as (
-- )
-- select * from movement_chain;
