# pgerp
An proof-of-concept ERP system using PostgreSQL.  Starting as a test of
transition tables, as such there is a consicous absence of additional indices.

This is a work in progress. Currently a system similar to double-entry
accounting is used to keep track of the flow of inventory. I am currently
working on average-cost assignment.

One of the premises is that "reality wins". An example would be that, in
theory, you cannot have a `stock` location that has fewer than 0 items in it.
However, reality is messy and if someone's going to claim they pulled an item
from a bin that we think has no items in it, well, by golly, we're wrong and we
should error when they pull the item. We should probably tell them something's
wonky and log it, but we shouldn't prevent them from doing the action.

# Test

Running `make clean && make` will drop and create the db "pgerp" (`make clean`)
and then load the schema and triggers and run a quick sample/test (`make`).

```sql
CREATE SCHEMA
SET
CREATE TABLE
CREATE TABLE
INSERT 0 5
CREATE TABLE
INSERT 0 4
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE FUNCTION
CREATE TRIGGER
CREATE FUNCTION
CREATE TRIGGER
SET
INSERT 0 1
INSERT 0 6
 location_id | location_type_id | location_lpn | account_type_id |  sku   | quantity
-------------+------------------+--------------+-----------------+--------+----------
           1 | supplier         | megacorp     | supplied        | THING1 |  0.00000
           2 | receiving        | megacorp     | received        | THING1 |  0.00000
           3 | stock            | A-B-C-D      | stocked         | THING1 |  0.00000
           4 | stock            | A-B-C-D      | commited        | THING1 |  0.00000
           5 | package          | 12345        | commited        | THING1 |  0.00000
           6 | package          | 12345        | shipped         | THING1 |  0.00000
(6 rows)

 posting_id | entry_id | location_id | quantity
------------+----------+-------------+----------
(0 rows)

Received 100 Widgets
INSERT 0 1
INSERT 0 2
 location_id | location_type_id | location_lpn | account_type_id |  sku   |  quantity
-------------+------------------+--------------+-----------------+--------+------------
           3 | stock            | A-B-C-D      | stocked         | THING1 |    0.00000
           4 | stock            | A-B-C-D      | commited        | THING1 |    0.00000
           5 | package          | 12345        | commited        | THING1 |    0.00000
           6 | package          | 12345        | shipped         | THING1 |    0.00000
           1 | supplier         | megacorp     | supplied        | THING1 | -100.00000
           2 | receiving        | megacorp     | received        | THING1 |  100.00000
(6 rows)

 posting_id | entry_id | location_id |  quantity
------------+----------+-------------+------------
          1 |        1 |           1 | -100.00000
          2 |        1 |           2 |  100.00000
(2 rows)

Stocked 50 of those widgets
INSERT 0 1
INSERT 0 2
 location_id | location_type_id | location_lpn | account_type_id |  sku   |  quantity
-------------+------------------+--------------+-----------------+--------+------------
           4 | stock            | A-B-C-D      | commited        | THING1 |    0.00000
           5 | package          | 12345        | commited        | THING1 |    0.00000
           6 | package          | 12345        | shipped         | THING1 |    0.00000
           1 | supplier         | megacorp     | supplied        | THING1 | -100.00000
           3 | stock            | A-B-C-D      | stocked         | THING1 |   50.00000
           2 | receiving        | megacorp     | received        | THING1 |   50.00000
(6 rows)

 posting_id | entry_id | location_id |  quantity
------------+----------+-------------+------------
          1 |        1 |           1 | -100.00000
          2 |        1 |           2 |  100.00000
          3 |        2 |           2 |  -50.00000
          4 |        2 |           3 |   50.00000
(4 rows)

Commited 12 of those widgets to fulfilling an order
INSERT 0 1
INSERT 0 2
 location_id | location_type_id | location_lpn | account_type_id |  sku   |  quantity
-------------+------------------+--------------+-----------------+--------+------------
           5 | package          | 12345        | commited        | THING1 |    0.00000
           6 | package          | 12345        | shipped         | THING1 |    0.00000
           1 | supplier         | megacorp     | supplied        | THING1 | -100.00000
           2 | receiving        | megacorp     | received        | THING1 |   50.00000
           4 | stock            | A-B-C-D      | commited        | THING1 |   12.00000
           3 | stock            | A-B-C-D      | stocked         | THING1 |   38.00000
(6 rows)

 posting_id | entry_id | location_id |  quantity
------------+----------+-------------+------------
          1 |        1 |           1 | -100.00000
          2 |        1 |           2 |  100.00000
          3 |        2 |           2 |  -50.00000
          4 |        2 |           3 |   50.00000
          5 |        3 |           3 |  -12.00000
          6 |        3 |           4 |   12.00000
(6 rows)

Picked 2 widgets into a shipping container
INSERT 0 1
INSERT 0 2
 location_id | location_type_id | location_lpn | account_type_id |  sku   |  quantity
-------------+------------------+--------------+-----------------+--------+------------
           6 | package          | 12345        | shipped         | THING1 |    0.00000
           1 | supplier         | megacorp     | supplied        | THING1 | -100.00000
           2 | receiving        | megacorp     | received        | THING1 |   50.00000
           3 | stock            | A-B-C-D      | stocked         | THING1 |   38.00000
           5 | package          | 12345        | commited        | THING1 |    2.00000
           4 | stock            | A-B-C-D      | commited        | THING1 |   10.00000
(6 rows)

 posting_id | entry_id | location_id |  quantity
------------+----------+-------------+------------
          1 |        1 |           1 | -100.00000
          2 |        1 |           2 |  100.00000
          3 |        2 |           2 |  -50.00000
          4 |        2 |           3 |   50.00000
          5 |        3 |           3 |  -12.00000
          6 |        3 |           4 |   12.00000
          7 |        4 |           4 |   -2.00000
          8 |        4 |           5 |    2.00000
(8 rows)

Shipped the widgets
INSERT 0 1
INSERT 0 2
 location_id | location_type_id | location_lpn | account_type_id |  sku   |  quantity
-------------+------------------+--------------+-----------------+--------+------------
           1 | supplier         | megacorp     | supplied        | THING1 | -100.00000
           2 | receiving        | megacorp     | received        | THING1 |   50.00000
           3 | stock            | A-B-C-D      | stocked         | THING1 |   38.00000
           4 | stock            | A-B-C-D      | commited        | THING1 |   10.00000
           6 | package          | 12345        | shipped         | THING1 |    2.00000
           5 | package          | 12345        | commited        | THING1 |    0.00000
(6 rows)

 posting_id | entry_id | location_id |  quantity
------------+----------+-------------+------------
          1 |        1 |           1 | -100.00000
          2 |        1 |           2 |  100.00000
          3 |        2 |           2 |  -50.00000
          4 |        2 |           3 |   50.00000
          5 |        3 |           3 |  -12.00000
          6 |        3 |           4 |   12.00000
          7 |        4 |           4 |   -2.00000
          8 |        4 |           5 |    2.00000
          9 |        5 |           5 |   -2.00000
         10 |        5 |           6 |    2.00000
(10 rows)

Commit another 12 of those widgets to fulfilling an order
This posting is not balance and will error
INSERT 0 1
ERROR:  1 Journal Entry(ies) Not Balanced
CONTEXT:  PL/pgSQL function function_check_zero_balance_journal_entry() line 12 at RAISE
 location_id | location_type_id | location_lpn | account_type_id |  sku   |  quantity
-------------+------------------+--------------+-----------------+--------+------------
           1 | supplier         | megacorp     | supplied        | THING1 | -100.00000
           2 | receiving        | megacorp     | received        | THING1 |   50.00000
           3 | stock            | A-B-C-D      | stocked         | THING1 |   38.00000
           4 | stock            | A-B-C-D      | commited        | THING1 |   10.00000
           6 | package          | 12345        | shipped         | THING1 |    2.00000
           5 | package          | 12345        | commited        | THING1 |    0.00000
(6 rows)

 posting_id | entry_id | location_id |  quantity
------------+----------+-------------+------------
          1 |        1 |           1 | -100.00000
          2 |        1 |           2 |  100.00000
          3 |        2 |           2 |  -50.00000
          4 |        2 |           3 |   50.00000
          5 |        3 |           3 |  -12.00000
          6 |        3 |           4 |   12.00000
          7 |        4 |           4 |   -2.00000
          8 |        4 |           5 |    2.00000
          9 |        5 |           5 |   -2.00000
         10 |        5 |           6 |    2.00000
(10 rows)
```
