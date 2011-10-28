# Manual Contents

 * [The dbgeni Concept](#concept)
   * [10 Second Tour](#10tour)
   * [Migration Script?](#migration_script)
   * [Code File?](#code_file)
 * [Requirements](#requirements)
   * [Sqlite](#requirements_sqlite)
   * [Oracle](#requirements_oracle)
 * [Install](#install)
 * [Default Setup](#default_setup)
 * [The Config File](#config_file)
   * [Parameter Section](#config_parameter)
   * [Environment Section](#config_environment)
   * [Default Config Filename](#config_default_config)
 * [Initialize The Database](#initialize)
 * [Migrations](#migrations)
   * [Generating Migrations](#migrations_generating)
   * [Milestones](#migrations_milestones)
 * [Stored Procedures](#stored_procedures)
   * [Generating Stored Procedure Files](#stored_procedures_generating)
 * [Logging](#logging)
 * [Setup Commands](#setup_commands)
    * [new](#setup_commands_new)
    * [new-config](#setup_commands_new-config)
    * [initialize](#setup_commands_initialize)
 * [Generator Commands](#generator_commands)
    * [migration](#generator_commands_migration)
    * [procedure](#generator_commands_procedure)
    * [function](#generator_commands_function)
    * [package](#generator_commands_package)
    * [trigger](#generator_commands_trigger)
    * [milestone](#generator_commands_milestone)
 * [Migration Commands](#migration_commands)
   * [list](#migrations_list)
   * [applied](#migrations_applied)
   * [outstanding](#migrations_outstanding)
   * [apply all](#migrations_apply_all)
   * [apply next](#migrations_apply_next)
   * [apply until](#migrations_apply_until)
   * [apply specific](#migrations_apply_specific)
   * [apply milestone](#migrations_apply_milestone)
   * [rollback all](#migrations_rollback_all)
   * [rollback last](#migrations_rollback_last)
   * [rollback until](#migrations_rollback_until)
   * [rollback specific](#migrations_rollback_specific)
   * [rollback milestone](#migrations_rollback_milestone)
 * [Milestone Commands](#milestone_commands)
   * [list](#milestone_commands_list)
 * [Code Commands](#code_commands)
   * [list](#code_commands_list)
   * [current](#code_commands_current)
   * [outstanding](#code_commands_outstanding)
   * [apply all](#code_apply_all)
   * [apply outstanding](#code_apply_outstanding)
   * [apply specific](#code_apply_specific)
   * [remove all](#code_remove_all)
   * [remove specific](#code_remove_specific)
 * [Option Switches](#option_switches)
   * [environment-name](#option_switches_environment_name)
   * [config-file](#option_switches_config)
   * [force](#option_switches_force)
   * [help](#option_switches_help)



# The dbgeni Concept<a id="concept"></a>

You should read the [Overview](/overview.html) section before reading this manual so you understand the problem dbgeni solves and gain a high level overview of how it operates.

## 10 Second Tour<a id="10tour"></a>

DBGeni is a command line utility that is implemented using Ruby and installed as a Ruby gem.

It requires a config file which defines the location of database migration scripts and stored procedure code named in a special format.

The config file also contains database connection details for various environments, and the name of a table in the database that tracks which migration scripts and code modules have been applied to the database.

Given the config file, database and a set of migration scripts and code files, dbgeni provides a set of commands to apply, rollback and query those migrations and code modules to make database changes as painless as possible.

## Migration Script?<a id="migration_script"></a>

A migration script is a plain old SQL file that contains commands to add, alter or drop tables, change data, add indexes etc. Basically any command that your database considers valid is allowed in the migration file - no special syntax is required, so it is possible to run the migrations with or without dbgeni.

## Code File?<a id="code_file"></a>

A code file is simply a file that contains the code for a single database stored procedure. This can be a package specification, package body, procedure, function or trigger, so long as it only contains one object and is named in the correct way dbgeni can apply it to the database.

# Requirements<a id="requirements"></a>

All DBGeni needs to run is the [Ruby](http://ruby-lang.org) programming language and the [RubyGems](http://rubygems.org/) package manager. No knowledge of Ruby is required to use it, but you need to install it.

Depending on the database you want to use, you will also need the drivers for that database.

## SQLite<a id="requirements_sqlite"></a>

 * Install the sqlite3 gem.
 * The sqlite3 shell is required and must be on your path. Get it from [the sqlite website](http://www.sqlite.org/download.html).

## Oracle<a id="requirements_oracle"></a>

 * Install the Oracle Client and ensure sqlplus works and is on your path. 
 * Install [ruby-oci8](http://ruby-oci8.rubyforge.org/en/)


# Install<a id="install"></a>

For now, dbgeni is not available in the Ruby gem libraries, so [download it](/downloads/dbgeni-0.1.0.gem) and install it locally:

    $ wget http://dbgeni.com/downloads/dbgeni-0.1.0.gem
    $ gem install dbgeni-0.1.0.gem

If Ruby is on your path, then after installation the dbgeni command should also be on your path. Running the following command will display the usage instructions:

    $ dbgeni --help


# Default Setup<a id="default_setup"></a>

DBGeni requires a config file containing database connection details and the location in which all the migration scripts are stored.

If you are creating a new project, the new command will create a directory structure and a skeleton config file:

    $ dbgeni new /path/to/new_project

This will create a directory structure as follows:

    /path/to/new_project            # Project Directory
    /path/to/new_project/.dbgeni    # Config file
    /path/to/new_project/migrations # Directory to hold migrations

By default a new SQLite database will be used, so it is safe to play around.

If you just want to create a skeleton config file in an existing project, use the new-config command:

    $ dbgeni new-config /path/to/config/.dbgeni

# The Config File<a id="config_file"></a>

The skeleton config file generated by the new or new-config commands is given below:


    # Parameters Section
    #
    # This specifies the location of the migrations directory
    migrations_directory "./migrations"

    # This specifies the location of the code directory
    code_directory "./code"
    
    # This specifies the type of database this installer is applied against
    # Valid values are oracle, sqlite however this is not validated at runtime
    # Default is sqlite
    database_type "sqlite"
    
    # This is the table the installer logs applied migrations in the database
    # The default is dbgeni_migrations
    database_table "dbgeni_migrations"
    
    # Environment Section
    #
    # There must be at least one environment, and at a minimum each environment
    # should define a username, database and password, except SQLite which only 
    # requires a database.
    #
    # Typically there will be more than one enviroment block detailing development,
    # test and production but any number of environments are valid provided there is at least one.
    
    environment('development') {
      database 'devdb.sqlite' # this must be here, or it will error. For Oracle, this is the TNS Name
    #   username ''            # this must be here, or it will error
    #   password ''            # If this value is missing, it will be promoted for if the env is used.
    #
    #   Other parameters can be defined here and will override global_parameters
    #   param_name 'value'
    }
    
    #
    # environment('test') {
    #   username 'user'         # this must be here, or it will error
    #   database 'testdb.sqlite # this must be here, or it will error. For Oracle, this is the TNS Name
    #   password ''             # If this value is missing, it will be promoted for if the env is used.
    # }

An important note about the config file is that it is Ruby code, therefore the syntax is important or it will not complile.The file contains two sections which are detailed below.

## Parameter Section<a id="config_parameter"></a>

This contains parameters which tell dbgeni where to find migrations, which database table to use to track migrations and what type (sqlite, Oracle etc) of database it will connect to. Details of the config options allowed are in the following sections.

### migrations_directory

The migrations_directory option defines where dbgeni will find migration files. It can be an absolute path, or normally a path relative to the location of the config file, eg:

    migrations_directory "./migrations"
    migrations_directory "/home/sodonnel/dbscripts"

If it is not specified the default is "./migrations".

### code_directory

The code\_directory option defines where dbgeni will find code files. It can be an absolute path, or normally a path relative to the location of the config file, eg:

    migrations_directory "./code"
    migrations_directory "/home/sodonnel/code"

If it is not specified the default is "./code".


### database_type

The database_type option is used to tell dbgeni what sort of database is the target for migrations scripts. The current set of allowed values is "sqlite" or "oracle", eg:

    database_type "oracle"
    database_type "sqlite"

If it is not specified the default is "sqlite".

### database_table

The database_table option is used to tell dbgeni which database table should be used to track applied, failed and rolled back migrations, eg:

    database_table "dbgeni_migrations"

If it is not specified the default is "dbgeni_migrations".

## Environment Section<a id="config_environment"></a>

This contains details about each environment dbgeni can connect to. In this release, the only useful parameters are database, username and password. In future releases other parameters can be defined here and used as parameters in SQL scripts.

There can be many environment definitions, but each should have a unique name. The idea is to create an environment section for each database you want to apply migrations against. An environment is defined using the syntax below:

    environment('<name>') {
      username 'user'
      password 'pass'
      database 'sqlite_file or Oracle TNS name'
    }

If there is only 1 environment, then dbgeni will use it as the default. If there are many environments, then you must specify which environment to use using the --environment-name switch (-e for short), eg:

    $ dbgeni migrations applied --environment-name test

## Default Config Filename<a id="config_default_config"></a>

By default, the config file is called .dbgeni if you run the dbgeni command it looks for a file called .dbgeni in the current directory, and if it does not find it, it will error:

    $ dbgeni migrations list
    The config file ./.dbgeni does not exist:  (expanded from ./.dbgeni) does not exist

If the config file is located elsewhere or does not have the default name, it must be specified with the --config-file switch (-c for short).


# Initialize the Database<a id="initialize"></a>

Before most of the dbgeni commands can be used, the target database must be initialized. This simply creates a table in the database, with the default name of dbgeni_migrations having the following structure:

    create table dbgeni_migrations
    (
      sequence_or_hash varchar2(1000) not null,
      migration_name   varchar2(4000) not null,
      migration_type   varchar2(20)   not null,
      migration_state  varchar2(20)   not null,
      start_dtm        date,
      completed_dtm    date
    )

If the database\_table parameter has been changed in the config file, it will override the default name.

If you attempt to run a command against an uninitialized database, dbgeni will error:

    ERROR - The database needs to be initialized with the command dbgeni initialize

The best way to initialize the database is using the initialize command:

    $ dbgeni initialize

    info - Database initialized successfully

Alternatively create the table structure given above manually.


# Migrations<a id="migrations"></a>

As far as dbgeni is concerned, a migration is a pair of files. One of the files contains SQL commands to make a change to the database, while the other file contains commands to reverse the operation. If one file contains a command to add a new table, then the other file should contain the equivalent drop table command. 

Sometimes it is not possible to reverse a database change if, for example, data was deleted, so it is possible to have an empty migration file that contains no commands.

The file that moves the database forward a version is known as the UP migration, while the one that performs the rollback is known as the DOWN migration.

For dbgeni to recognise migrations, they must be stored in the "migrations_directory" and named in a specific way:

    <TIMESTAMP>_<UP/DOWN>_<NAME>.sql

 * TIMESTAMP is the current date and time in the format YYYYMMDDHH24MI
 * UP/DOWN indicates if the script is used to move the database forward a version or rollback a version
 * NAME is a name that describes the migration.

Migrations should always be created in pairs, with both an UP and a DOWN script, eg:

    201108101531_up_create_users.sql
    201108101531_down_create_users.sql

## Generating Migrations<a id="migrations_generating"></a>

A dbgeni command can be used to create a pair of empty migration files with the current timestamp:

    $ dbgeni generate migration create_users_table

Before the migrations can be applied to the database, the empty files should be edited to contain some SQL statements. 

There is no special syntax for the code in the migration files - any SQL that is valid to run against the target database can be included.

For example, generate a migration and edit the UP file to add a create table statement, eg:

    create table users (
      id integer,
      username varchar2(255)
    );

Next edit the DOWN file and add the equivalent drop statement, eg:

    drop table users;

This migration is now in a state that it can be applied to the target database and rolled back easily using the dbgeni [migration_commands](#migration_commands), but can still be run manually if necessary.

## Milestones<a id="migrations_milestones"></a>

Over the lifetime of a database application, many migrations will be added and they will normally be pushed to production in batches. Each time new migrations are pushed to production, the database structure moves to a new version, determined by which migrations have been applied. As migrations are applied in increasing date stamp order, the version of the database is determined by the newest migration that is to be applied for the release. 

The final migration to be applied during a release is known as a milestone migration, and a "milestone" can be created to mark it.

A milestone is set by creating a file in the migrations_directory, that has the name of the milestone as the filename and an extension of ".milestone". The file should contain the filename of the milestone migration on the first line and nothing else. For example, to set a milestone called release_1.0, with the migration 201101011754_up_create_customer_table.sql as the milestone, first create a file in the migrations directory:

    $ release_1.0.milestone

And the contents of the file:

    201101011754_up_create_customer_table.sql

You can use the [milestone generator](#generator_commands_milestone) to easily create milestones, and the [milestones](#milestone_commands) command to list any that exist.

    $ dbgeni milestones list

To apply or rollback all migrations to a particular milestone, use the migrations apply or rollback back command, for example:

    $ dbgeni migrations apply    milestone <name_of_milestone>
    $ dbgeni migrations rollback milestone <name_of_milestone>

# Stored Procedures<a id="stored_procedures"></a>

Many database applications make use of stored procedures and dbgeni can install them too. 

All code should be stored in the "code_directory", and the naming of the files is important. The filename should be given the same name as the object name in the database. For example, if a code file creates a procedure called insert_customer, then the file should be called "insert_customer.prc". In this case, the name of the file identifies the database object, and the file extension identifies the type of object.

There are 5 allowed file extensions:

 * pks - Package specification
 * pks - Package body
 * prc - Procedure
 * fnc - Function
 * trg - Trigger

The naming of the files is very important for removing stored procedures, as the appropriate drop command will be generated from the filename, eg:

    insert_customer.prc => drop procedure insert_customer;
    insert_customer.fnc => drop function  insert_customer;

Dbgeni considers stored procedure code to be in one of two states:

 * Outstanding - This is code which has never been applied to the database, or has been changed since it was last applied.
 * Current - This is code that has been applied to the database, and has not been changed since it was last applied.

To determine if a code module is current, dbgeni generates a hash of the relevant file in the code_directory, and compares it to a hash that was stored in the dbgeni_migrations table on the database. If the two match, then the code is considered current. 

If the code module is changed on the database manually or using another tool, then dbgeni will not see the change, and will still consider the module current.

When a code module is current, it does not necessarily mean it complied without error on the database. Unlike with migrations, dbgeni does not error if a code module compiles with errors.

## Generating Stored Procedure Files<a id="stored_procedures_generating"></a>

A dbgeni command can be used to create empty code files named in the correct way:

    $ dbgeni generate package   manage_customer
    $ dbgeni generate procedure insert_customer
    $ dbgeni generate function  select_customer
    $ dbgeni generate trigger   biud_on_customer

Each of these commands will create a file in the code_directory with the correct name and some boiler plate code. In the case of a package, it will generate a file for each of the package specification and body.

Before the code can be applied to the database, the template file should be edited to contain valid code and then use the [code_commands](#code_commands) to apply it to the database.


# Logging<a id="logging"></a>

Each time dbgeni runs, it writes to a logfile called log.txt stored in the log directory. The log directory is created in the same directory as the .dbgeni config file and will be created automatically if it does not exist.

Each time a migration is applied or rolled back, an additional log file is created for each migration file executed. This file contains all the input and output produced by the database when running the SQL statements. If dbgeni reports problems applying a migration, these log files are the place to look for errors. They are named with a timestamp followed by the migration filename, eg:

    20110922153123_201108101531_up_create_users.sql


# Setup Commands<a id="setup_commands"></a>

The setup commands are used to help configure a new or existing project to use dbgeni.

## new<a id="setup_commands_new"></a>

The new command will create a directory structure for a new project and a skeleton config file.

    $ dbgeni new <path to directory>

For example:

    $ dbgeni new cool_project
    
    creating directory: cool_project
    creating directory: cool_project/migrations
    creating file: cool_project/.dbgeni

The directory can be relative or absolute and will result in the directory being created, and it will contain a migrations directory and the skeleton .dbgeni config file.


## new-config<a id="setup_commands_new-config"></a>

The new-config command will add the .dbgeni skeleton config file to the given directory.

    $ dbgeni new-config <path to directory>

For example:

    $ dbgeni new-config cool_project

    creating file: cool_project/.dbgeni


## initialize<a id="setup_commands_initialize"></a>

The initialize command is used to initialize the database so dbgeni can track applied migrations. 

    $ dbgeni initialize

This creates a single table in the target database, which by default is called dbgeni_migrations. The table has the following structure and can be created manually if necessary:

    create table dbgeni_migrations
    (
      sequence_or_hash varchar2(1000) not null,
      migration_name   varchar2(4000) not null,
      migration_type   varchar2(20)   not null,
      migration_state  varchar2(20)   not null,
      start_dtm        date,
      completed_dtm    date
    )


# Generator Commands<a id="generator_commands"></a>

Generator commands are helpers to make it easier to create files named in the format dbgeni requires.

## migration<a id="generator_commands_migration"></a>

The migration generator takes a single parameter, which is the name of a migration, and generates a pair of empty UP and DOWN migration files with the correct filenames:

    $ dbgeni generate migration <name_of_migration>

For example:

    $ dbgeni generate migration create_users_table

    creating: /home/sodonnell/cool_project/./migrations/201109221657_up_create_users_table.sql
    creating: /home/sodonnell/cool_project/./migrations/201109221657_down_create_users_table.sql

The generated files will have a TIMESTAMP set to the current date and time.

## procedure<a id="generator_commands_procedure"></a>

The procedure generator takes a single parameter, which is the name of the procedure on the database, and generates a template file with the correct filename:

    $ dbgeni generate procedure <name_of_procedure>

For example:

    $ dbgeni generate procedure insert_customer

    creating: /home/sodonnell/cool_project/./code/insert_customer.prc


## function<a id="generator_commands_function"></a>

The function generator takes a single parameter, which is the name of the function on the database, and generates a template file with the correct filename:

    $ dbgeni generate function <name_of_function>

For example:

    $ dbgeni generate function get_customer

    creating: /home/sodonnell/cool_project/./code/get_customer.fnc


## package<a id="generator_commands_package"></a>

The package generator takes a single parameter, which is the name of the package on the database, and generates two template files with the correct filename:

    $ dbgeni generate package <name_of_package>

For example:

    $ dbgeni generate package manage_customer

    creating: /home/sodonnell/cool_project/./code/manage_customer.pks
    creating: /home/sodonnell/cool_project/./code/manage_customer.pkb


## trigger<a id="generator_commands_trigger"></a>

The trigger generator takes a single parameter, which is the name of the trigger on the database, and generates a template file with the correct filename:

    $ dbgeni generate trigger <name_of_trigger>

For example:

    $ dbgeni generate trigger biud_customer

    creating: /home/sodonnell/cool_project/./code/biud_customer.trg


## milestone<a id="generator_commands_milestone"></a>

The milestone generator takes two parameters. The first is the name of the milestone, and the second is the name of the migration to use for the milestone. The migration must exist and can be specified using the migration name or filename:

    $ dbgeni generate milestone <name_of_milestone> <migration>

For example:

    $ dbgeni generate milestone release_1.0 201101011754::create_customer

OR

    $ dbgeni generate milestone release_1.0 201101011754_up_create_customer.sql

    creating: /home/sodonnell/cool_project/./migrations/release_1.0.milestone

# Migration Commands<a id="migration_commands"></a>

The migration command has several sub-commands to list, apply and rollback migrations. For all migration commands the --environment-name (-e) and --config-file (-c) switches can be used if necessary.

## list<a id="migrations_list"></a>

To list all migrations stored in the migration directory, use the list sub-command:

    $ dbgeni migrations list

## applied<a id="migrations_applied"></a>

To see all the migrations that have been applied to the target database, use the applied sub-command:

    $ dbgeni migrations applied

## outstanding<a id="migrations_outstanding"></a>

To see all the migrations that have not been applied to the target database and are outstanding, use the outstanding sub-command:

    $ dbgeni migrations outstanding


## Apply Migrations

One of several apply sub-commands can be used to run the migration script against the target database. When a migration is run, the contents of the UP script are applied to the target database.

Normally migrations are applied in increasing TIMESTAMP order. Sometimes two different developers will add migrations that are out of sequence. The best way to correct this problem is to rename the files so the TIMESTAMPS put the files in the correct order.

### apply all<a id="migrations_apply_all"></a>

To apply all migrations that are outstanding, use the all command, eg:

    $ dbgeni migrations apply all

If there are no outstanding migrations or a problem is encountered applying a migration an error will be displayed and dbgeni will not continue.

### apply next<a id="migrations_apply_next"></a>

To apply only the next migration that is outstanding, use the next command, eg:

    $ dbgeni migrations apply next

If there are no outstanding migrations or a problem is encountered applying the migration an error will be displayed.

### apply until<a id="migrations_apply_until"></a>

To apply from the first outstanding migration up to and including a specific migration, use the until command, eg:

    $ dbgeni migrations apply until 201108101531::create_users

This is useful if there are a large number of outstanding migrations, and you know you want stop applying before the final one.

If the specified migration is already applied, does not exist or there are no outstanding migrations the command will error. 

If a problem is encountered applying a migration an error will be displayed and dbgeni will not continue.


### apply specific<a id="migrations_apply_specific"></a>

To apply a single or several migrations out of their normal sequence, you can specify specific migrations to apply on the command line, eg:

    $ dbgeni migrations apply 201108101531::create_users 201108110825::create_user_details 

If there are no outstanding migrations or a problem is encountered applying a migration an error will be displayed and dbgeni will not continue.

### apply milestone<a id="migrations_apply_milestone"></a>

TODO


### Forcing Migrations

Normally when applying migrations, if an error is raised by any SQL statement in the file, dbgeni stops processing immediately - it does not complete the current migration or move onto any subsequent ones. Sometimes you want to force a migration to complete, knowing some of the errors are not important. For all the migration commands, the --force (-f for short) switch can be specified with prevents dbgeni stopping when it encounters most errors, eg:

    $ dbgeni migrations apply all --force

## Rollback Migrations

When a migration is rolled back the contents of the DOWN script are applied to the target database. For rollbacks, the DOWN scripts are applied in *decending* TIMESTAMP order. There is a set of rollback commands that mirror the migration apply commands.

### rollback all<a id="migrations_rollback_all"></a>

To rollback everything, use the all sub-command. If things work correctly, this will remove the entire application from the database:

    $ dbgeni migrations rollback all

If there are no applied migrations or a problem is encountered rolling back a migration an error will be displayed and dbgeni will not continue.

### rollback last<a id="migrations_rollback_last"></a>

To rollback just the last applied migration, use the last sub-command, eg:

    $ dbgeni migrations rollback last

If there are no applied migrations or a problem is encountered rolling back a migration an error will be displayed.

### rollback until<a id="migrations_rollback_until"></a>

To rollback from the last applied migration down to but NOT including a specific migration, use the until command, eg:

    $ dbgeni migrations rollback until 201108101531::create_users

This is useful if there are a large number of applied migrations, and you know you want stop rolling back before the first one.

If the specified migration has not been applied, does not exist or there are no outstanding migrations the command will error. 

If a problem is encountered rolling back a migration an error will be displayed and dbgeni will not continue.


### rollback specific<a id="migrations_rollback_specific"></a>

To rollback a single or several migrations out of their normal sequence, you can specify specific migrations to rollback on the command line, eg:

    $ dbgeni migrations rollback 201108101531::create_users 201108110825::create_user_details 

If any of the migrations are not applied or a problem is encountered rolling back a migration an error will be displayed and dbgeni will not continue.

### rollback milestone<a id="migrations_rollback_milestone"></a>

TODO

### Forcing Rollbacks

As with applying migrations, rollbacks can be forced through with the --force (-f for short) switch. This is particularly useful if an apply failed part way through and you want to clean up any changes it made without worrying about where the original migration failed.

    $ dbgeni migrations rollback all --force

# Milestone Commands<a id="milestone_commands"></a>

## list<a id="milestone_commands_list"></a>

TODO

# Code Commands<a id="code_commands"></a>

The code command has several sub-commands to list, apply and remove code modules. For all code commands the --environment-name (-e) and --config-file (-c) switches can be used if necessary.

## list<a id="code_commands_list"></a>

To list all code modules stored in the code\_directory, use the list sub-command:

    $ dbgeni code list 

## current<a id="code_commands_current"></a>

To list all code modules stored in the code\_directory that are considered current, use the current sub-command:

    $ dbgeni code current

A module is considered current if the hash of the file in the code\_directory is the same as the hash stored in the dbgeni\_migrations table in the database.

## outstanding<a id="code_commands_outstanding"></a>

To list all code modules stored in the code\_directory that are considered outstanding, use the outstanding sub-command:

    $ dbgeni code outstanding

A module is considered outstanding if the hash of the file in the code directory is not the same as the hash stored in the dbgeni_migrations table in the database or there is no entry in the database for the file.

## Apply Code Modules

One of several apply sub-commands can be used to install code modules onto the database. Code modules are applied to the database in increasing alphabetic order.

### apply all<a id="code_apply_all"></a>

To apply all the code modules in the code\_directory, whether they are current or outstanding, use the all command, eg:

    $ dbgeni code apply all

This command will result in a total refresh of all code on the database. It is best used for initial installs, or on test or development environments.

### apply outstanding<a id="code_apply_outstanding"></a>

To apply the code modules in the code\_directory that are outstanding, use the outstanding command, eg:

    $ dbgeni code apply outstanding

### apply specific<a id="code_apply_specific"></a>

To apply a single or several code modules, you can specify the filenames on the command line, eg:

    $ dbgeni code apply create_cust.prc get_cust.fnc

If a code module is current, then an error will be displayed and dbgeni will stop processing. If you want to force a current module to be applied to the database, use the --force switch.

## Remove Code Modules

One of several sub-commands can be used to remove code modules from the database.

### remove all<a id="code_remove_all"></a>

To remove all code modules that are in the code\_directory, use the all command, eg:

    $ dbgeni remove all

Note this command will not remove code modules that were not installed by dbgeni.

### remove specific<a id="code_remove_specific"></a>

To remove one or several specific code modules, you can specify the filenames on the command line, eg:

    $ dbgeni code remove create_cust.prc get_cust.fnc

The remove command will not error if the code module is not installed.


# Option Switches<a id="option_switches"></a>

Command line options allow the runtime behavour of dbgeni to be controlled.

## --environment-name<a id="option_switches_environment_name"></a>

Specifying --environment-name (-e for short) is required if more than one environment is defined in the config file. 

For example:

    $ dbgeni migrations applied --environment-name uat1
    $ dbgeni migrations applied -e uat1

An error will be raised if the environment name specified does not exist.

## --config-file<a id="option_switches_config"></a>

Specifying --config-file (-c for short) allows dbgeni to run with a config file that is not in the current directory or has not got the default name.

For example:

    $ dbgeni migrations applied --config-file /home/sodonnel/configs/.dbgeni_config_one
    $ dbgeni migrations applied -c /home/sodonnel/configs/.dbgeni_config_one

If the config file does not exist an error will be raised.

## --force<a id="option_switches_force"></a>

Specifying --force (-f for short) allows dbgeni to continue processing migrations when it encounters errors. This can be useful when developing new migrations, rolling back failed migrations and in some production scenarios.

For example:

    $ dbgeni migrations apply all --force
    $ dbgeni migrations apply all -f

## --help<a id="option_switches_help"></a>

Specifying --help (-h for short) makes dbgeni display usage instructions for the command.

For example:

    $ dbgeni --help
    $ dbgeni migrations --help
    $ dbgeni migrations -h


