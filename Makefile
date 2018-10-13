all: install test clean

install:
	cat journal.sql \
		  journal_triggers.sql \
      purchasing.sql \
		| psql pgerp

test:
	cat test.sql | psql pgerp

clean:
	dropdb pgerp
	createdb pgerp
