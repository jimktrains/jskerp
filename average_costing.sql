-- this doesn't work...yet ;)

with to_postings as (
  select posting_id, entry_id, account_id, quantity
  from posting 
  where quantity >= 0
),
from_postings as (
  select posting_id, entry_id, account_id, quantity 
  from posting 
  where quantity < 0
),
recursive to_postings_po_cost as (
  select entry_id, account_id, quantity, unit_cost
  from purchase_order_item 
  left join to_postings using (entry_id)
  union all
  select entry_id, account_id, quantity, unit_cost
  from from_postings
  join (
    select entry_id, sum(quantity * unit_cost) / sum(quantity) as unit_cost,
    from to_postings_po_cost
    group by entry_id
  ) x on x.entry_id =
),
select *
from from_postings_average_po_cost
;
