# Requirements

All DBGeni needs to run is the [Ruby](http://ruby-lang.org) programming language and the [RubyGems](http://rubygems.org/) package manager. No knowledge of Ruby is required to use it, but you need to install it.


# Download

Download the [DBGeni GEM]()

# Install

    $ gem install dbgeni-0.1.0.gem

If Ruby is on your path, then the dbgeni command should display the usage instructions:

    $ dbgeni --help

# Create a new project

If you are creating a new project, then you can use the new command to create a directory structure for you:

    $ dbgeni new /path/to/new_project

This will create a directory structure as follows:

    /path/to/new_project            # Project Directory
    /path/to/new_project/.dbgeni    # Config file
    /path/to/new_project/migrations # Directory to hold migrations

By default a new SQLite database will be used, so it is safe to play around.

# Initialize the Database

    $ cd /path/to/new_project
    $ dbgeni initialize

All this command does is create a table in the database, called dbgeni_migrations.

# Generate a migration

    $ dbgeni generate migration create_users_table

This will generate a pair of files in the migrations directory in the correctly named format. Open the 'up' file and add some DDL code, eg:

    create table users (
      id integer,
      username varchar2(255)
    );

Open the down file and add the equivalent drop statement:

    drop table users;


# Apply the outstanding migrations

    $ dbgeni migrations apply all

# Rollback Migrations

    $ dbgeni migrations rollback all








# List Migrations

    $ dbgeni migrations list

# List Applied Migrations

    $ dbgeni migrations applied

# List Outstanding Migrations

    $ dbgeni migrations outstanding



## Existing Project

If you want to use DBGeni on an existing project, then all that needs added is the config file, named ".dbgeni" by default. Create it using the configure command, and pass it the full path to the confg file:

    $ dbgeni configure /path/to/project/.dbgeni




## Installing Ruby

Version 1.9.2 is the best version of Ruby right now, but 1.8.7 will work fine too. 

Get the download for your platform and install it. For Windows, grab the [Ruby Installer](http://rubyinstaller.org/downloads/) and for other platforms have a look [here](http://rubygems.org/pages/download).

Next you need to install the Ruby Package manager, [RubyGems](http://rubygems.org/). 

[Download it]() and installed 
