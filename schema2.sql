create extension btree_gist;

-- create table gapless_counter ( table_name text not null primary key, last_id integer not null );
-- create or replace function get_next_gapless_id(table_name regclass) returns integer as $$
-- declare
--     next_value integer;
-- begin
--     execute format('update gapless_counter set last_id = last_id + 1 where table_name = %s returning last_id', table_name);
--     return next_value;
-- end;
-- $$ language plpgsql;

create table item (
  item_id bigserial primary key
);

create table customer (
  customer_id bigserial primary key
);

create table customer_address (
  customer_address_id bigserial primary key,
  customer_id bigint references customer(customer_id)
);

create table inventory_type (
  inventory_type_id bigserial primary key,
  name text not null,
);
insert into inventory_type values
('received'),
('stocked'),
('commited'),

create table inventory (
  inventory_id bigserial primary key,
  item_id bigint not null references item(item_id),
  inventory_type_id references inventory_type(inventory_type_id) not null,
  inventory_location_id references inventory_location(inventory_location_id),
  exclude using gist (inventory_location_id with =, item_id with <>),
  unique (inventory_location_id, item_id, inventory_type_id)
);
create index inventory_item_item_type_idx on inventory(item_id, inventory_type);

create table inventory_location (
  inventory_location_id bigserial primary key,
  amount integer not null,
);

create table shipping_container (
  customer_address references customer_address(customer_address_id),
) inherits (inventory_location);

create inventory_bin (
) inherits (inventory_location);

create table journal (
  -- Yes, this might have gaps :(
  entry_id bigserial primary key,
);

create table posting (
  -- Yes, this might have gaps :(
  posting_id bigserial primary key,
  entry_id bigint not null references journal,
  inventory_location_id bigint not null references inventory,
  amount integer not null
);

create table "order" (
  order_id bigserial primary key,
);

create table order_item (
  order_item_id bigserial primary key,
  item_id bigint not null references item(item_id),
  order_id bigint not null references "order"(order_id),
);

