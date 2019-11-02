# pgerp
An proof-of-concept ERP system using PostgreSQL.  Starting as a test of
transition tables, as such there is a consicous absence of additional indices.

This is a work in progress. Currently a system similar to double-entry
accounting is used to keep track of the flow of inventory. Basic Average and
First-in-first-out (FIFO) costings are implemented.

Currently working on building out commiting items from an order.

# Test

Running `make clean && make` will drop and create the db "pgerp" (`make clean`)
and then load the schema and triggers and run a quick sample/test (`make`).

```sql
dropdb --if-exists jskerp
createdb jskerp
psql -v ON_ERROR_STOP=1 -f setup.sql jskerp
CREATE SCHEMA
SET
psql -v ON_ERROR_STOP=1 -f journal.sql jskerp
SET
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
psql -v ON_ERROR_STOP=1 -f journal_triggers.sql jskerp
SET
CREATE FUNCTION
CREATE TRIGGER
CREATE FUNCTION
CREATE TRIGGER
CREATE FUNCTION
CREATE TRIGGER
CREATE FUNCTION
CREATE TRIGGER
CREATE TRIGGER
psql -v ON_ERROR_STOP=1 -f average_costing.sql jskerp
SET
CREATE TABLE
CREATE FUNCTION
CREATE TRIGGER
CREATE FUNCTION
CREATE TRIGGER
psql -v ON_ERROR_STOP=1 -f fifo_costing.sql jskerp
SET
CREATE TABLE
CREATE FUNCTION
CREATE TRIGGER
psql -v ON_ERROR_STOP=1 -f test_setup.sql jskerp
SET
INSERT 0 5
INSERT 0 6
INSERT 0 1
INSERT 0 1
INSERT 0 2
INSERT 0 5
INSERT 0 12
psql -v ON_ERROR_STOP=1 -f test.sql jskerp
SET
Received 100 THING1 @ $10/unit and 25 WIDGET2 @ $10/unit
INSERT 0 1
INSERT 0 4
Averae Costs
 account_id | quantity  | average_cost 
------------+-----------+--------------
          1 | -100.0000 |       0.0000
          2 |  100.0000 |      10.0000
          3 |    0.0000 |       0.0000
          4 |    0.0000 |       0.0000
          5 |    0.0000 |       0.0000
          6 |    0.0000 |       0.0000
          7 |  -25.0000 |       0.0000
          8 |   25.0000 |      25.0000
          9 |    0.0000 |       0.0000
         10 |    0.0000 |       0.0000
         11 |    0.0000 |       0.0000
         12 |    0.0000 |       0.0000
(12 rows)

FIFO Cost
 account_id | entry_id | quantity | measure | unit_cost 
------------+----------+----------+---------+-----------
          2 |        1 | 100.0000 |  1.0000 |   10.0000
          8 |        1 |  25.0000 | 40.0000 |   25.0000
(2 rows)

Received 100 THING1 @ $15/unit
INSERT 0 1
INSERT 0 2
Averae Costs
 account_id | quantity  | average_cost 
------------+-----------+--------------
          1 | -200.0000 |       0.0000
          2 |  200.0000 |      15.0000
          3 |    0.0000 |       0.0000
          4 |    0.0000 |       0.0000
          5 |    0.0000 |       0.0000
          6 |    0.0000 |       0.0000
          7 |  -25.0000 |       0.0000
          8 |   25.0000 |      25.0000
          9 |    0.0000 |       0.0000
         10 |    0.0000 |       0.0000
         11 |    0.0000 |       0.0000
         12 |    0.0000 |       0.0000
(12 rows)

FIFO Cost
 account_id | entry_id | quantity | measure | unit_cost 
------------+----------+----------+---------+-----------
          2 |        1 | 100.0000 |  1.0000 |   10.0000
          2 |        2 | 100.0000 |  1.0000 |   15.0000
          8 |        1 |  25.0000 | 40.0000 |   25.0000
(3 rows)

Stocked 50 THING1s
INSERT 0 1
INSERT 0 2
Averae Costs
 account_id | quantity  | average_cost 
------------+-----------+--------------
          1 | -200.0000 |       0.0000
          2 |  150.0000 |      15.0000
          3 |   50.0000 |      15.0000
          4 |    0.0000 |       0.0000
          5 |    0.0000 |       0.0000
          6 |    0.0000 |       0.0000
          7 |  -25.0000 |       0.0000
          8 |   25.0000 |      25.0000
          9 |    0.0000 |       0.0000
         10 |    0.0000 |       0.0000
         11 |    0.0000 |       0.0000
         12 |    0.0000 |       0.0000
(12 rows)

FIFO Cost
 account_id | entry_id | quantity | measure | unit_cost 
------------+----------+----------+---------+-----------
          2 |        1 |  50.0000 |  1.0000 |   10.0000
          2 |        2 | 100.0000 |  1.0000 |   15.0000
          3 |        3 |  50.0000 |  1.0000 |   10.0000
          8 |        1 |  25.0000 | 40.0000 |   25.0000
(4 rows)

Receive 100 THING1 @ $13/unit
INSERT 0 1
INSERT 0 2
Averae Costs
 account_id | quantity  | average_cost 
------------+-----------+--------------
          1 | -300.0000 |       0.0000
          2 |  250.0000 |      13.0000
          3 |   50.0000 |      15.0000
          4 |    0.0000 |       0.0000
          5 |    0.0000 |       0.0000
          6 |    0.0000 |       0.0000
          7 |  -25.0000 |       0.0000
          8 |   25.0000 |      25.0000
          9 |    0.0000 |       0.0000
         10 |    0.0000 |       0.0000
         11 |    0.0000 |       0.0000
         12 |    0.0000 |       0.0000
(12 rows)

FIFO Cost
 account_id | entry_id | quantity | measure | unit_cost 
------------+----------+----------+---------+-----------
          2 |        1 |  50.0000 |  1.0000 |   10.0000
          2 |        2 | 100.0000 |  1.0000 |   15.0000
          2 |        4 | 100.0000 |  1.0000 |   13.0000
          3 |        3 |  50.0000 |  1.0000 |   10.0000
          8 |        1 |  25.0000 | 40.0000 |   25.0000
(5 rows)

Stocked another 50 THING1s
INSERT 0 1
INSERT 0 2
Averae Costs
 account_id | quantity  | average_cost 
------------+-----------+--------------
          1 | -300.0000 |       0.0000
          2 |  200.0000 |      13.0000
          3 |  100.0000 |      13.0000
          4 |    0.0000 |       0.0000
          5 |    0.0000 |       0.0000
          6 |    0.0000 |       0.0000
          7 |  -25.0000 |       0.0000
          8 |   25.0000 |      25.0000
          9 |    0.0000 |       0.0000
         10 |    0.0000 |       0.0000
         11 |    0.0000 |       0.0000
         12 |    0.0000 |       0.0000
(12 rows)

FIFO Cost
 account_id | entry_id | quantity | measure | unit_cost 
------------+----------+----------+---------+-----------
          2 |        2 | 100.0000 |  1.0000 |   15.0000
          2 |        4 | 100.0000 |  1.0000 |   13.0000
          3 |        3 |  50.0000 |  1.0000 |   10.0000
          3 |        5 |  50.0000 |  1.0000 |   10.0000
          8 |        1 |  25.0000 | 40.0000 |   25.0000
(5 rows)

Commited 12 THING1 to fulfilling an order
INSERT 0 1
INSERT 0 2
Averae Costs
 account_id | quantity  | average_cost 
------------+-----------+--------------
          1 | -300.0000 |       0.0000
          2 |  200.0000 |      13.0000
          3 |   88.0000 |      13.0000
          4 |   12.0000 |      13.0000
          5 |    0.0000 |       0.0000
          6 |    0.0000 |       0.0000
          7 |  -25.0000 |       0.0000
          8 |   25.0000 |      25.0000
          9 |    0.0000 |       0.0000
         10 |    0.0000 |       0.0000
         11 |    0.0000 |       0.0000
         12 |    0.0000 |       0.0000
(12 rows)

FIFO Cost
 account_id | entry_id | quantity | measure | unit_cost 
------------+----------+----------+---------+-----------
          2 |        2 | 100.0000 |  1.0000 |   15.0000
          2 |        4 | 100.0000 |  1.0000 |   13.0000
          3 |        3 |  38.0000 |  1.0000 |   10.0000
          3 |        5 |  50.0000 |  1.0000 |   10.0000
          4 |        6 |  12.0000 |  1.0000 |   10.0000
          8 |        1 |  25.0000 | 40.0000 |   25.0000
(6 rows)

Picked 2 THING1 into a shipping container
INSERT 0 1
INSERT 0 2
Averae Costs
 account_id | quantity  | average_cost 
------------+-----------+--------------
          1 | -300.0000 |       0.0000
          2 |  200.0000 |      13.0000
          3 |   88.0000 |      13.0000
          4 |   10.0000 |      13.0000
          5 |    2.0000 |      13.0000
          6 |    0.0000 |       0.0000
          7 |  -25.0000 |       0.0000
          8 |   25.0000 |      25.0000
          9 |    0.0000 |       0.0000
         10 |    0.0000 |       0.0000
         11 |    0.0000 |       0.0000
         12 |    0.0000 |       0.0000
(12 rows)

FIFO Cost
 account_id | entry_id | quantity | measure | unit_cost 
------------+----------+----------+---------+-----------
          2 |        2 | 100.0000 |  1.0000 |   15.0000
          2 |        4 | 100.0000 |  1.0000 |   13.0000
          3 |        3 |  38.0000 |  1.0000 |   10.0000
          3 |        5 |  50.0000 |  1.0000 |   10.0000
          4 |        6 |  10.0000 |  1.0000 |   10.0000
          5 |        7 |   2.0000 |  1.0000 |   10.0000
          8 |        1 |  25.0000 | 40.0000 |   25.0000
(7 rows)

Shipped those 2 widgets
INSERT 0 1
INSERT 0 2
Averae Costs
 account_id | quantity  | average_cost 
------------+-----------+--------------
          1 | -300.0000 |       0.0000
          2 |  200.0000 |      13.0000
          3 |   88.0000 |      13.0000
          4 |   10.0000 |      13.0000
          5 |    0.0000 |      13.0000
          6 |    2.0000 |      13.0000
          7 |  -25.0000 |       0.0000
          8 |   25.0000 |      25.0000
          9 |    0.0000 |       0.0000
         10 |    0.0000 |       0.0000
         11 |    0.0000 |       0.0000
         12 |    0.0000 |       0.0000
(12 rows)

FIFO Cost
 account_id | entry_id | quantity | measure | unit_cost 
------------+----------+----------+---------+-----------
          2 |        2 | 100.0000 |  1.0000 |   15.0000
          2 |        4 | 100.0000 |  1.0000 |   13.0000
          3 |        3 |  38.0000 |  1.0000 |   10.0000
          3 |        5 |  50.0000 |  1.0000 |   10.0000
          4 |        6 |  10.0000 |  1.0000 |   10.0000
          6 |        8 |   2.0000 |  1.0000 |   10.0000
          8 |        1 |  25.0000 | 40.0000 |   25.0000
(7 rows)

Commit another 12 THING1 to fulfilling another order
This posting is not balance and will error
INSERT 0 1
psql:test.sql:159: ERROR:  Journal Entry(ies) Not Balanced
CONTEXT:  PL/pgSQL function function_check_zero_balance_journal_entry() line 9 at RAISE
Averae Costs
 account_id | quantity  | average_cost 
------------+-----------+--------------
          1 | -300.0000 |       0.0000
          2 |  200.0000 |      13.0000
          3 |   88.0000 |      13.0000
          4 |   10.0000 |      13.0000
          5 |    0.0000 |      13.0000
          6 |    2.0000 |      13.0000
          7 |  -25.0000 |       0.0000
          8 |   25.0000 |      25.0000
          9 |    0.0000 |       0.0000
         10 |    0.0000 |       0.0000
         11 |    0.0000 |       0.0000
         12 |    0.0000 |       0.0000
(12 rows)

FIFO Cost
 account_id | entry_id | quantity | measure | unit_cost 
------------+----------+----------+---------+-----------
          2 |        2 | 100.0000 |  1.0000 |   15.0000
          2 |        4 | 100.0000 |  1.0000 |   13.0000
          3 |        3 |  38.0000 |  1.0000 |   10.0000
          3 |        5 |  50.0000 |  1.0000 |   10.0000
          4 |        6 |  10.0000 |  1.0000 |   10.0000
          6 |        8 |   2.0000 |  1.0000 |   10.0000
          8 |        1 |  25.0000 | 40.0000 |   25.0000
(7 rows)

Moving WIDGET2 5@1.5yds from 8 to 9
INSERT 0 1
INSERT 0 2
Averae Costs
 account_id | quantity  | average_cost 
------------+-----------+--------------
          1 | -300.0000 |       0.0000
          2 |  200.0000 |      13.0000
          3 |   88.0000 |      13.0000
          4 |   10.0000 |      13.0000
          5 |    0.0000 |      13.0000
          6 |    2.0000 |      13.0000
          7 |  -25.0000 |       0.0000
          8 |   20.0000 |      25.0000
          9 |    5.0000 |      25.0000
         10 |    0.0000 |       0.0000
         11 |    0.0000 |       0.0000
         12 |    0.0000 |       0.0000
(12 rows)

FIFO Cost
 account_id | entry_id | quantity | measure | unit_cost 
------------+----------+----------+---------+-----------
          2 |        2 | 100.0000 |  1.0000 |   15.0000
          2 |        4 | 100.0000 |  1.0000 |   13.0000
          3 |        3 |  38.0000 |  1.0000 |   10.0000
          3 |        5 |  50.0000 |  1.0000 |   10.0000
          4 |        6 |  10.0000 |  1.0000 |   10.0000
          6 |        8 |   2.0000 |  1.0000 |   10.0000
          8 |        1 |   1.0000 | 32.5000 |   25.0000
          8 |        1 |  24.0000 | 40.0000 |   25.0000
          9 |       10 |   5.0000 |  1.5000 |   25.0000
(9 rows)

Moving WIDGET2 25@40yds from 8 to 10
This will error because we do not have enough
INSERT 0 1
psql:test.sql:199: ERROR:  Unable to fulfil posting_id=24 for WIDGET2 qty=1@40.0000
CONTEXT:  PL/pgSQL function function_update_fifo_cost() line 226 at RAISE
Averae Costs
 account_id | quantity  | average_cost 
------------+-----------+--------------
          1 | -300.0000 |       0.0000
          2 |  200.0000 |      13.0000
          3 |   88.0000 |      13.0000
          4 |   10.0000 |      13.0000
          5 |    0.0000 |      13.0000
          6 |    2.0000 |      13.0000
          7 |  -25.0000 |       0.0000
          8 |   20.0000 |      25.0000
          9 |    5.0000 |      25.0000
         10 |    0.0000 |       0.0000
         11 |    0.0000 |       0.0000
         12 |    0.0000 |       0.0000
(12 rows)

FIFO Cost
 account_id | entry_id | quantity | measure | unit_cost 
------------+----------+----------+---------+-----------
          2 |        2 | 100.0000 |  1.0000 |   15.0000
          2 |        4 | 100.0000 |  1.0000 |   13.0000
          3 |        3 |  38.0000 |  1.0000 |   10.0000
          3 |        5 |  50.0000 |  1.0000 |   10.0000
          4 |        6 |  10.0000 |  1.0000 |   10.0000
          6 |        8 |   2.0000 |  1.0000 |   10.0000
          8 |        1 |   1.0000 | 32.5000 |   25.0000
          8 |        1 |  24.0000 | 40.0000 |   25.0000
          9 |       10 |   5.0000 |  1.5000 |   25.0000
(9 rows)

```
