# Running the Suite

To run the tests, use:

    $ ruby test_runner.rb

Run like this, it will run only the base tests, that use sqlite.

For more involved tests, you need to edit the helper.rb file to put in the connection details for each database.

There are specific tests for oracle, sybase, and mysql - to run the base tests, plus those for a give db:

    $ ruby test_runner.rb oracle mysql

There are also CLI tests, which right now require SQLite and both MySQL and Oracle to be available. These are somewhat like integration tests, and nothing is stubbed. There are also quite slow and print a lot of stuff to the screen:

    $ ruby test_runner.rb cli

If you just want to run everything:

    $ ruby test_runner.rb all

If you want to run everything except some DBs or CLI, then:

    $ ruby test_runner.rb all nooracle nocli

Sybase only works on JRuby - it will not run sybase tests on MRI Ruby even if you ask it to.


## Gotchas

For Oracle, ensure you have set your TNS_ADMIN correctly.


# To Fix

 * The test file oracle/dbgeni_base_code_oracle_test.rb is all that really tests the DBGeni::Base Code interface, but it totally relies on Oracle being available. I think it could be change to stub a lot of the inner class calls out and operate without any database, or perhaps with a SQLite DB instead.

 * CLI tests - somehow control which databases need to be up for them to work.

 * Load database connection details out of a yaml file or something, rather than having to edit the helper.rb code.

 * Document how to create database users with correct permissions to allow tests to run successfully.
