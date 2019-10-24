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
dropdb --if-exists pgerp
createdb pgerp
psql -v ON_ERROR_STOP=1 -f journal.sql pgerp
SET
CREATE TABLE
CREATE TABLE
INSERT 0 5
CREATE TABLE
INSERT 0 4
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
psql -v ON_ERROR_STOP=1 -f journal_triggers.sql pgerp
CREATE FUNCTION
CREATE TRIGGER
CREATE FUNCTION
CREATE TRIGGER
CREATE FUNCTION
CREATE TRIGGER
psql -v ON_ERROR_STOP=1 -f purchasing.sql pgerp
SET
CREATE TABLE
psql -v ON_ERROR_STOP=1 -f average_costing.sql pgerp
SET
CREATE TABLE
CREATE FUNCTION
CREATE TRIGGER
CREATE FUNCTION
CREATE TRIGGER
psql -v ON_ERROR_STOP=1 -f test.sql pgerp
SET
INSERT 0 2
INSERT 0 5
INSERT 0 12
 location_id | location_type_id | location_lpn  
-------------+------------------+---------------
           1 | supplier         | megacorp
           2 | receiving        | Shipper.54321
           3 | stock            | A-B-C-D
           4 | package          | Shipper.12345
           5 | receiving        | Shipper.98765
(5 rows)

 account_id | location_id | account_type_id |   sku   | quantity 
------------+-------------+-----------------+---------+----------
          1 |           1 | supplied        | THING1  |  0.00000
          2 |           2 | received        | THING1  |  0.00000
          3 |           3 | stocked         | THING1  |  0.00000
          4 |           3 | commited        | THING1  |  0.00000
          5 |           4 | commited        | THING1  |  0.00000
          6 |           4 | shipped         | THING1  |  0.00000
          7 |           1 | supplied        | WIDGET2 |  0.00000
          8 |           2 | received        | WIDGET2 |  0.00000
          9 |           3 | stocked         | WIDGET2 |  0.00000
         10 |           3 | commited        | WIDGET2 |  0.00000
         11 |           4 | commited        | WIDGET2 |  0.00000
         12 |           4 | shipped         | WIDGET2 |  0.00000
(12 rows)

 posting_id | entry_id | account_id | quantity | unit_cost | sku 
------------+----------+------------+----------+-----------+-----
(0 rows)

 account_id | average_cost 
------------+--------------
          1 |       0.0000
          2 |       0.0000
          3 |       0.0000
          4 |       0.0000
          5 |       0.0000
          6 |       0.0000
          7 |       0.0000
          8 |       0.0000
          9 |       0.0000
         10 |       0.0000
         11 |       0.0000
         12 |       0.0000
(12 rows)

Received 100 THING1 @ $10/unit and 25 WIDGET2 @ $10/unit
INSERT 0 1
INSERT 0 4
 account_id |  quantity  | average_cost 
------------+------------+--------------
          1 | -100.00000 |       0.0000
          2 |  100.00000 |      10.0000
          3 |    0.00000 |       0.0000
          4 |    0.00000 |       0.0000
          5 |    0.00000 |       0.0000
          6 |    0.00000 |       0.0000
          7 |  -25.00000 |       0.0000
          8 |   25.00000 |      10.0000
          9 |    0.00000 |       0.0000
         10 |    0.00000 |       0.0000
         11 |    0.00000 |       0.0000
         12 |    0.00000 |       0.0000
(12 rows)

Received 100 THING1 @ $15/unit
INSERT 0 1
INSERT 0 2
 account_id |  quantity  | average_cost 
------------+------------+--------------
          1 | -200.00000 |       0.0000
          2 |  200.00000 |      12.5000
          3 |    0.00000 |       0.0000
          4 |    0.00000 |       0.0000
          5 |    0.00000 |       0.0000
          6 |    0.00000 |       0.0000
          7 |  -25.00000 |       0.0000
          8 |   25.00000 |      10.0000
          9 |    0.00000 |       0.0000
         10 |    0.00000 |       0.0000
         11 |    0.00000 |       0.0000
         12 |    0.00000 |       0.0000
(12 rows)

Stocked 50 THING1s
INSERT 0 1
INSERT 0 2
 account_id |  quantity  | average_cost 
------------+------------+--------------
          1 | -200.00000 |       0.0000
          2 |  150.00000 |      12.5000
          3 |   50.00000 |      12.5000
          4 |    0.00000 |       0.0000
          5 |    0.00000 |       0.0000
          6 |    0.00000 |       0.0000
          7 |  -25.00000 |       0.0000
          8 |   25.00000 |      10.0000
          9 |    0.00000 |       0.0000
         10 |    0.00000 |       0.0000
         11 |    0.00000 |       0.0000
         12 |    0.00000 |       0.0000
(12 rows)

Receive 100 THING1 @ $13/unit
INSERT 0 1
INSERT 0 2
 account_id |  quantity  | average_cost 
------------+------------+--------------
          1 | -300.00000 |       0.0000
          2 |  250.00000 |      12.7000
          3 |   50.00000 |      12.5000
          4 |    0.00000 |       0.0000
          5 |    0.00000 |       0.0000
          6 |    0.00000 |       0.0000
          7 |  -25.00000 |       0.0000
          8 |   25.00000 |      10.0000
          9 |    0.00000 |       0.0000
         10 |    0.00000 |       0.0000
         11 |    0.00000 |       0.0000
         12 |    0.00000 |       0.0000
(12 rows)

Stocked another 50 THING1s
INSERT 0 1
INSERT 0 2
 account_id |  quantity  | average_cost 
------------+------------+--------------
          1 | -300.00000 |       0.0000
          2 |  200.00000 |      12.7000
          3 |  100.00000 |      12.6000
          4 |    0.00000 |       0.0000
          5 |    0.00000 |       0.0000
          6 |    0.00000 |       0.0000
          7 |  -25.00000 |       0.0000
          8 |   25.00000 |      10.0000
          9 |    0.00000 |       0.0000
         10 |    0.00000 |       0.0000
         11 |    0.00000 |       0.0000
         12 |    0.00000 |       0.0000
(12 rows)

Commited 12 THING1 to fulfilling an order
INSERT 0 1
INSERT 0 2
 account_id |  quantity  | average_cost 
------------+------------+--------------
          1 | -300.00000 |       0.0000
          2 |  200.00000 |      12.7000
          3 |   88.00000 |      12.6000
          4 |   12.00000 |      12.6000
          5 |    0.00000 |       0.0000
          6 |    0.00000 |       0.0000
          7 |  -25.00000 |       0.0000
          8 |   25.00000 |      10.0000
          9 |    0.00000 |       0.0000
         10 |    0.00000 |       0.0000
         11 |    0.00000 |       0.0000
         12 |    0.00000 |       0.0000
(12 rows)

Picked 2 THING1 into a shipping container
INSERT 0 1
INSERT 0 2
 account_id |  quantity  | average_cost 
------------+------------+--------------
          1 | -300.00000 |       0.0000
          2 |  200.00000 |      12.7000
          3 |   88.00000 |      12.6000
          4 |   10.00000 |      12.6000
          5 |    2.00000 |      12.6000
          6 |    0.00000 |       0.0000
          7 |  -25.00000 |       0.0000
          8 |   25.00000 |      10.0000
          9 |    0.00000 |       0.0000
         10 |    0.00000 |       0.0000
         11 |    0.00000 |       0.0000
         12 |    0.00000 |       0.0000
(12 rows)

Shipped those 2 widgets
INSERT 0 1
INSERT 0 2
 account_id |  quantity  | average_cost 
------------+------------+--------------
          1 | -300.00000 |       0.0000
          2 |  200.00000 |      12.7000
          3 |   88.00000 |      12.6000
          4 |   10.00000 |      12.6000
          5 |    0.00000 |      12.6000
          6 |    2.00000 |      12.6000
          7 |  -25.00000 |       0.0000
          8 |   25.00000 |      10.0000
          9 |    0.00000 |       0.0000
         10 |    0.00000 |       0.0000
         11 |    0.00000 |       0.0000
         12 |    0.00000 |       0.0000
(12 rows)

Commit another 12 THING1 to fulfilling another order
This posting is not balance and will error
INSERT 0 1
Makefile:13: recipe for target 'test' failed
psql:test.sql:109: ERROR:  Journal Entry(ies) Not Balanced
CONTEXT:  PL/pgSQL function function_check_zero_balance_journal_entry() line 9 at RAISE
make: *** [test] Error 3
```
