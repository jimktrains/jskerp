SET search_path TO inventory, public;

-- WIP
-- Eventually this will capture more details about purchasing and receiving.

create table purchase_order_item (
  purchase_order_item_id bigserial primary key,
  unit_cost decimal(10,2) not null check (unit_cost >= 0),
  entry_id bigint,
  unique (purchase_order_item_id, entry_id)
);
