PSQL_OPTS=-v ON_ERROR_STOP=1
DB=jskerp

install:
	psql ${PSQL_OPTS} -f setup.sql ${DB}
	psql ${PSQL_OPTS} -f journal.sql ${DB}
	psql ${PSQL_OPTS} -f journal_triggers.sql ${DB}
	psql ${PSQL_OPTS} -f average_costing.sql ${DB}
	psql ${PSQL_OPTS} -f fifo_costing.sql ${DB}
test:
	psql ${PSQL_OPTS} -f test_setup.sql ${DB}
	psql ${PSQL_OPTS} -f test.sql ${DB}

clean:
	dropdb --if-exists ${DB}
	createdb ${DB}
