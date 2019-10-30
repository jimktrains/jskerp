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
  item_id bigint not null references item,
  base_price numeric(10,4) not null check(price >= 0)
);

create table shipping_carrier (
  shipping_carrier_id bigserial primary key,
  name text unique
);

create table shipping_carrier_service (
  shipping_carrier_service_id bigserial primary key,
  shipping_carrier_id bigint not null references shipping_carrier,
  name text unique
);

create table shipment (
  shipment_id bigserial primary key,
  shipping_carrier_service_id bigint references shipping_carrier,
  tracking_number text
);

create table shipment_items (
  shipment_item_id bigserial primary key,
  shipment_account_id bigint references shipment_account,
  sale_item_id bigint references sale_item,
  weight_oz int,
  declared_value numeric(10,4),
  insured_value numeric(10,4)
);

create table shipment_account (
  account_id bigint references account primary key,
  shipment_id bigint references shipment,
  lpn text not null,
  weight_oz int, -- This may be different from the sum of shipment_items.
);

create table sale_account (
  sale_id bigint references sale,
  account_id bigint references account,
  primary key (sale_id, account_id)
);
