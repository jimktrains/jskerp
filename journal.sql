create schema inventory;

SET search_path TO inventory, public;

create table item (
  sku text primary key
);

create table account_type (
  account_type_id text primary key
);
insert into account_type (account_type_id) values
('supplied'),
('received'),
('stocked'),
('commited'),
('shipped')
;

create table location_type (
  location_type_id text primary key
);
insert into location_type (location_type_id) values
('supplier'),
('receiving'),
('stock'),
('package')
;

create table location (
  location_id bigserial primary key,
  location_type_id text not null references location_type,
  location_lpn text not null,
  account_type_id text not null references account_type,
  sku text not null references item,
  quantity decimal(10,5) not null,
  unique (location_type_id, location_lpn, account_type_id, sku)
);

create table journal (
  entry_id bigserial primary key
);

create table posting (
  posting_id bigserial primary key,
  entry_id bigint not null references journal,
  location_id bigint not null references location,
  quantity decimal(10,5) not null
);
