# Download

Download [dbgeni-0.1.0.gem](/dbgeni-0.1.0.gem)

# Install

DBGeni requires [Ruby](http://rubylang.org) and [Rubygems]().

    $ gem install /path/to/downloads/dbgeni-0.1.0.gem

# Experiment

By default, dbgeni uses a new SQLite database, so it is easy to experiment.

# Create a new project

    $ dbgeni new /path/to/project

# Initialize the database 

    $ cd /path/to/project
    $ dbgeni initialize

# Create a migration

    $ dbgeni generate migration my_first_migration

# Apply Migrations

    $ dbgeni migrations apply all

# More information

Have a look at the [overview](/overview.html) and the [manual](/manual.html) to learn how DBGeni works and all the other features.