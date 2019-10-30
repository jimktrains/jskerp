SET search_path TO inventory, public;

create table unit_of_measure (
  unit_of_measure_id bigserial primary key,
  name text not null,
  incremental numeric(10,4) not null check(incremental > 0),
  divisible boolean not null,
  combinable boolean not null
);

create function check_measure_increment()
returns trigger
as $$
declare
  diff numeric(10,4);
  uom_incremental numeric(10,4);
  uom_name text;
begin
  select incremental,
         name
  into uom_incremental,
       uom_name
  from unit_of_measure
  where unit_of_measure_id = new.unit_of_measure_id;

  if diff <> 0 then
    raise '% is not an increment of % for % (uom=%) (%)', new.measure, uom_incremental, uom_name, new.unit_of_measure_id, diff;
  end if;

  return new;
end;
$$ language plpgsql;

create table item (
  sku text primary key,
  unit_of_measure_id bigint not null references unit_of_measure,
  unique (sku, unit_of_measure_id)
);

create table account_type (
  account_type_id text primary key
);

create table location_type (
  location_type_id text primary key
);

create table location (
  location_id bigserial primary key,
  location_type_id text not null references location_type,
  location_lpn text not null,
  unique (location_type_id, location_lpn)
);

create table account (
  account_id bigserial primary key,
  location_id bigint references location,
  account_type_id text not null references account_type,
  sku text not null references item,
  quantity decimal(10,4) not null,
  measure decimal(10,4) not null,
  unit_of_measure_id bigint references unit_of_measure,
  foreign key (sku, unit_of_measure_id) references item(sku, unit_of_measure_id),
  unique (location_id, account_type_id, sku),
  unique (account_id, sku),
  unique (account_id, sku, unit_of_measure_id)
);

create trigger trigger_account_check_measure
before insert or update
on account
for each row
execute procedure check_measure_increment();

create table journal (
  entry_id bigserial primary key
);

create table posting (
  posting_id bigserial primary key,
  entry_id bigint not null references journal,
  account_id bigint not null references account,
  sku text not null references item,
  quantity integer not null,
  measure decimal(10,4) not null check(measure > 0),
  unit_of_measure_id bigint references unit_of_measure,
  unit_cost decimal(10,4),
  unique(account_id, entry_id),
  -- The way I've written the accounting portion, unit_costs can only be
  -- introduced on debits.
  check((unit_cost is null) or (quantity < 0)),
  foreign key (account_id, sku, unit_of_measure_id) references account(account_id, sku, unit_of_measure_id)
);

create trigger trigger_posting_check_measure
before insert or update
on posting
for each row
execute procedure check_measure_increment();
