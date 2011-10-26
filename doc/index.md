# Requirements

DBGeni requires [Ruby](http://rubylang.org) and [Rubygems](http://rubygems.org). 

At runtime, database drivers are required too:

 * For Oracle ensure you have a working sqplus and install [oci8](http://ruby-oci8.rubyforge.org/)
 * For Sqlite, ensure the sqlite3 command line shell works and install the sqlite3 gem

# Install

Download [dbgeni-0.1.0.gem](/downloads/dbgeni-0.1.0.gem) and install it locally: 

    $ wget http://dbgeni.com/downloads/dbgeni-0.1.0.gem
    $ gem install dbgeni-0.1.0.gem

At the moment dbgeni is not on Rubyforge.

# Create a new project

By default, dbgeni uses a new SQLite database, so it is easy to experiment.

    $ dbgeni new /path/to/project

# Initialize the database 

    $ cd /path/to/project
    $ dbgeni initialize

# Create a migration

    $ dbgeni generate migration my_first_migration

# Apply Migrations

    $ dbgeni migrations apply all

# Apply Stored Procedures

    $ dbgeni code apply all

# More information

Have a look at the [overview](/overview.html) and the [manual](/manual.html) to learn how DBGeni works and all the other features.