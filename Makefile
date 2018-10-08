test:
	cat journal.sql \
		  journal_triggers.sql \
		  test.sql \
	| psql pgerp

clean:
	dropdb pgerp
	createdb pgerp
