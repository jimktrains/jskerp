set search_path TO inventory, public;

-- WIP
-- Eventually this'll capture what's needed for a commerce system
-- and allow inventory to be commited, picked, and shipped.

create table customer (
  customer_id bigserial primary key
);

create table sale (
  sale_id bigserial primary key,
  customer_id bigint references customer
);

create table sale_item (
  sale_item_id bigserial primary key,
  sale_id bigint not null references sale,
  sku text not null references item,
  quantity int not null,
  measure numeric(10,4) not null,
  unit_of_measure_id bigint not null,
  foreign key (item_id, unit_of_measure_id) references item(item_id, unit_of_measure_id)
);

create table shipment (
  shipment_id bigserial primary key,
  shipping_carrier_service text,
  tracking_number text
);

create table shipment_items (
  shipment_item_id bigserial primary key,
  shipment_account_id bigint references shipment_account,
  sale_item_id bigint references sale_item
);

create table shipment_account (
  account_id bigint references account primary key,
  shipment_id bigint references shipment
);

create table sale_account (
  sale_id bigint references sale,
  account_id bigint references account,
  primary key (sale_id, account_id)
);
