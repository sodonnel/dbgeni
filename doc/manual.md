# Manual Contents

 * [The dbgeni Concept](#concept)
   * [10 Second Tour](#10tour)
   * [Migration Script?](#migration_script)
   * [Code File?](#code_file)
 * [Requirements](#requirements)
 * [Install](#install)
 * [Database Requirements](#database_requirements)
   * [Sqlite](#requirements_sqlite)
   * [Oracle](#requirements_oracle)
   * [Mysql](#requirements_mysql)
   * [Sybase](#requirements_sybase)
 * [Default Setup](#default_setup)
 * [The Config File](#config_file)
   * [Parameter Section](#config_parameter)
   * [Environment Section](#config_environment)
   * [Default Config Filename](#config_default_config)
 * [Initialize The Database](#initialize)
 * [Migrations](#migrations)
   * [Generating Migrations](#migrations_generating)
   * [Milestones](#migrations_milestones)
 * [DML Migrations](#dml_migrations)
 * [Stored Procedures](#stored_procedures)
   * [Installation Order](#stored_procedures_order)
   * [Oracle Specific](#stored_procedures_oracle)
   * [MySQL Specific](#stored_procedures_mysql)
   * [Sybase Specific](#stored_procedures_sybase)
   * [Generating Stored Procedure Files](#stored_procedures_generating)
 * [Logging](#logging)
 * [Plugins](#plugins)
   * [Hook Points](#plugins_hooks)
   * [Enable](#plugins_enable)
   * [Coding Plugins](#plugins_coding)
   * [Aborting Execution](#plugins_abort)
   * [Order of Execution](#plugins_order)
 * [Setup Commands](#setup_commands)
    * [new](#setup_commands_new)
    * [new-config](#setup_commands_new-config)
    * [initialize](#setup_commands_initialize)
 * [Generator Commands](#generator_commands)
    * [migration](#generator_commands_migration)
    * [dml migration](#generator_commands_dml_migration)
    * [procedure](#generator_commands_procedure)
    * [function](#generator_commands_function)
    * [package](#generator_commands_package)
    * [trigger](#generator_commands_trigger)
    * [milestone](#generator_commands_milestone)
 * [Migration Commands](#migration_commands)
   * [list](#migrations_list)
   * [applied](#migrations_applied)
   * [outstanding](#migrations_outstanding)
   * [Sybase Specific](#migrations_sybase)
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
 * [DML Migration Commands](#dml_migration_commands)
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
   * [Forcing Code](#code_forcing)
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


# Install<a id="install"></a>

For now, dbgeni is not available in the Ruby gem libraries, so [download it](/downloads/dbgeni-0.5.0.gem) and install it locally:

    $ wget http://dbgeni.com/downloads/dbgeni-0.5.0.gem
    $ gem install dbgeni-0.5.0.gem

If Ruby is on your path, then after installation the dbgeni command should also be on your path. Running the following command will display the usage instructions:

    $ dbgeni --help

# Database Requirements<a id="database_requirements"></a>

Depending on the database you want to use, you will also need the drivers for that database.

## SQLite<a id="requirements_sqlite"></a>

 * Install the sqlite3 gem.
 * The sqlite3 shell is required and must be on your path. Get it from [the sqlite website](http://www.sqlite.org/download.html).

## Oracle<a id="requirements_oracle"></a>

 * Install the Oracle Client and ensure sqlplus works and is on your path. 
 * Install [ruby-oci8](http://ruby-oci8.rubyforge.org/en/)

Alternatively, JRuby can be used to connect to Oracle. The oci8 driver will not work on JRuby, so instead download the Oracle JDBC drivers (ojdbc6.jar) and put then in the JRuby lib directory.

## MySQL<a id="requirements_mysql"></a>

 * Install the mysql command line tool, usually by simply installing MySQL, and ensure it is on your path
 * Install the ruby-mysql gem

## Sybase<a id="requirements_sybase"></a>

As there are no working native Sybase drivers for Ruby, JDBC is required to connect to the database. For that reason JRuby must be used when applying migrations and code to Sybase.

From JRuby 1.7.0, it defaults to Ruby 1.9 mode. Dbgeni requires Ruby 1.9 mode to be enabled, so if you are using JRuby less than 1.7.0 the --1.9 flag must be passed to JRuby, preferably by setting the environment variable:

    JRUBY_OPTS=--1.9

In addition to JRuby, the following components are required:

 * Install the Sybase client, isql, and ensure it is on your path.
 * Ensure any databases are in the sql.ini file (and you can connect to them from isql)
 * [Download the open source jTDS drivers](http://jtds.sourceforge.net/) and put them in the JRuby lib directory, eg:

    C:\jruby-1.6.5\lib\jtds-1.2.5.jar


# Default Setup<a id="default_setup"></a>

DBGeni requires a config file containing database connection details and the location in which all the migration scripts are stored.

If you are creating a new project, the new command will create a directory structure and a skeleton config file:

    $ dbgeni new /path/to/new_project

This will create a directory structure as follows:

    /path/to/new_project            # Project Directory
    /path/to/new_project/.dbgeni    # Config file
    /path/to/new_project/migrations # Directory to hold migrations
    /path/to/new_project/dml        # Directory to hold dml migrations
    /path/to/new_project/code       # Directory to hold stored procedure codes

By default a new SQLite database will be used, so it is safe to play around.

If you just want to create a skeleton config file in an existing project, use the new-config command:

    $ dbgeni new-config /path/to/config/.dbgeni

# The Config File<a id="config_file"></a>

The skeleton config file generated by the new or new-config commands is given below:


    # Parameters Section
    #
    # This specifies the location of the migrations directory
    migrations_directory "./migrations"

    # This specifies the location of the dml migrations directory
    dml_directory "./dml"

    # This specifies the location of the code directory
    code_directory "./code"

    # This specifes the location of the plugin directory. Specifying this parameter
    # enables plugins
    # plugin_directory "./dbgeni_plugins"
    
    # This specifies the type of database this installer is applied against
    # Valid values are oracle, mysql, sqlite, sybase however this is not validated at runtime
    database_type "sqlite"
    
    # This is the table the installer logs applied migrations in the database
    # The default is dbgeni_migrations
    database_table "dbgeni_migrations"

    # Use the include_file option to load another config file, perhaps
    # containing environment details for many different environments in one place
    #
    # include_file '/path/to/include/file'

    # Environment Section
    #
    # There must be at least one environment, and at a minimum each environment
    # should define a username, database and password (except sqlite which only
    # requires a database to be specified)
    #
    # Typically there will be more than one enviroment block detailing development,
    # test and production but any number of environments are valid provided there is at least one.
    #
    # The environments can be defined here or in an included file.
    
    # Defaults - this section is optional and can be used to define parameters that must
    # appear in every environment, for example install_schema. If a parameter is defined
    # here, and also defined in the environment, then the value in the environment block
    # will override the default. If many default blocks are specified, in included files
    # for example, the parameters are merged. If any parameters are duplicated, the last to
    # be loaded will used.
    #
    # defaults {
    #  username 'scott'
    # }
    
    environment('development') {
    
    ### SQLITE
      database 'testdb.sqlite' # This is the only required connection parameter for sqlite
    
    ### ORACLE
    #
    #  database 'DEV1'    # This is the name of an entry in the tns_names.ora file
    #  username 'scott'   # This is the username to connect as, and also the default schema
    #  password 'tiger'   # This is the password for the username
    #
    #  install_schema 'other' # Optional: If dbgeni connects as a database user, but the application
                              # is owned by another user, set the application schema here
    
    ### MYSQL
    #
    #  database 'DEV1'      # This is the database to use after connection
    #  username 'scott'     # This is the username to connect as
    #  password 'tiger'     # This is the password for the username
    #  hostname '127.0.0.1' # This is the hostname or IP mysql is running on
                            # For localhost use the IP 127.0.0.1 or it will not work.
    #  port     '3306'      # This the port of the mysql service
    
    ### SYBASE
    #
    #  database 'DEV1'       # This is the database to use after connection
    #  username 'scott'      # This is the username to connect as
    #  password 'tiger'      # This is the password for the username
    #  hostname '127.0.0.1'  # This is the hostname or IP sybase is running on
    #  port     '3306'       # This the port of the sybase service
    #  sybase_service 'dev1' # THis is the sybase service name defined in the sql.ini file
    
    
    #   Other parameters can be defined here to be used as replacement parameters in scripts
    #   or in plugins in future versions of dbgeni.
    #   param_name 'value'
    }

    # environment('test') {
    #    ### SQLITE
    #      database 'testdb.sqlite' # This is the only required connection parameter for sqlite
    # }

An important note about the config file is that it is Ruby code, therefore the syntax is important or it will not compile.The file contains two sections which are detailed below.

## Parameter Section<a id="config_parameter"></a>

This contains parameters which tell dbgeni where to find migrations, which database table to use to track migrations and what type (sqlite, Oracle etc) of database it will connect to. Details of the config options allowed are in the following sections.

### migrations_directory

The migrations_directory option defines where dbgeni will find migration files. It can be an absolute path, or normally a path relative to the location of the config file, eg:

    migrations_directory "./migrations"
    migrations_directory "/home/sodonnel/dbscripts"

If it is not specified the default is "./migrations".

### dml_directory

The dml_directory option defines where dbgeni will find dml migration files. It can be an absolute path, or normally a path relative to the location of the config file, eg:

    migrations_directory "./dml"
    migrations_directory "/home/sodonnel/dmlscripts"

If it is not specified the default is "./dml".


### code_directory

The code\_directory option defines where dbgeni will find code files. It can be an absolute path, or normally a path relative to the location of the config file, eg:

    migrations_directory "./code"
    migrations_directory "/home/sodonnel/code"

If it is not specified the default is "./code".


### plugin_directory

The plugin\_directory option defines where dbgeni will find plugin scripts. It can be an absolute path, or normally a path relative to the location of the config file, eg:

    plugin_directory "./dbgeni_plugins"
    plugin_directory "/home/sodonnel/dbgeni_plugins"

Setting this directory enables plugins and if it is set, the directory must exist.

### database_type

The database_type option is used to tell dbgeni what sort of database is the target for migrations scripts. The current set of allowed values is "sqlite", "oracle", "mysql" and "sybase" eg:

    database_type "oracle"
    database_type "sqlite"

If it is not specified the default is "sqlite".

### database_table

The database_table option is used to tell dbgeni which database table should be used to track applied, failed and rolled back migrations, eg:

    database_table "dbgeni_migrations"

If it is not specified the default is "dbgeni_migrations".

### include_file

If you have many target databases, or an application made up of many schemas, it could make sense to keep all the environment details in a single file, and then include that into the main .dbgeni file used by the installer. This can be achieved using the include_file command:

    include_file 'path/to/include/file'

The included file can contain any options permitted in the main dbgeni config, and it can even include other files.


## Environment Section<a id="config_environment"></a>

This contains details about each environment dbgeni can connect to. In this release, the only useful parameters are a subset of database, install\_schema, username, password, hostname, port and sybase_service. In future releases other parameters can be defined here and used as parameters in SQL scripts.

There can be many environment definitions, but each should have a unique name. If the same environment is defined more than once, then the newest parameters are merged with the existing parameters as the config file is processed from top to bottom.

The idea is to create an environment section for each database you want to apply migrations or code against. An environment is defined using the syntax below:

    environment('development') {
      database 'sqlite filename or oracle tns name or mysql database or sybase database'
      install_schema 'oracle only, optional. Specify the name of the schema to install objects if it is different from the  username'
      username 'database login user - ignored for sqlite'
      password 'database password. Will prompt for input if blank'
      hostname 'IP address of mysql or sybase server - ignored for Oracle and sqlite'
      port     'Port mysql or sybase server runs on - ignored for Oracle and sqlite'
      sybase_service 'name of a sybase instance, defined in the sql.ini file'
    }


If there is only 1 environment, then dbgeni will use it as the default. If there are many environments, then you must specify which environment to use using the --environment-name switch (-e for short), eg:

    $ dbgeni migrations applied --environment-name test

The password field in the environment section is handled differently than other fields. If it is left blank in the config file, dbgeni will prompt for it to be entered when it is needed. No other fields in the config file behave this way - if the value is not in the file and is required dbgeni will error.

### Install Schema

On Oracle systems, each user that can connect to the database has its own database, or schema, that can contain database objects.

With MySQL and Sybase, a user cannot own objects. They must be installed into a database by a user with the appropriate permissions.

Therefore, when specifying the connection details for MySQL and Sybase, both a username and a database are required in the .dbgeni config file.

In Oracle, the database parameter defines the Oracle instance to connect to with the given username. By default, this username will also be the schema any migrations or code files are installed into. On many systems this is all that is required, however sometimes applications are installed by connecting as an admin user and creating the objects in a different schema. For Oracle, if the target schema is not the same as the user connecting to the database, then the 'install_schema' parameter should be specified, defining the target schema.

### Defaults

Sometimes the only thing that varies between different environments is the database name, or password. Common parameters can be defined once in the config file and inherited by all environments using a 'defaults' block:

    defaults {
        username 'scott'
        password 'tiger'
    }

The parameters specified in the default block provide a starting template for all environments. If a value is also defined in the environment block, it overrides the default. If it is not specified, the default value is used.

If multiple default blocks are defined they are merged in an identical way to environments.


## Default Config Filename<a id="config_default_config"></a>

By default, the config file is called .dbgeni if you run the dbgeni command it looks for a file called .dbgeni in the current directory, and if it does not find it, it will error:

    $ dbgeni migrations list
    The config file ./.dbgeni does not exist:  (expanded from ./.dbgeni) does not exist

If the config file is located elsewhere or does not have the default name, it must be specified with the --config-file switch (-c for short).


# Initialize the Database<a id="initialize"></a>

Before most of the dbgeni commands can be used, the target database must be initialized. This simply creates a table in the database, with the default name of dbgeni_migrations having the following structure:

    create table dbgeni_migrations
    (
      sequence_or_hash varchar2(100) not null,
      migration_name   varchar2(1100) not null,
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

Alternatively create the table structure given above manually, the primary key should be on three columns:

 * sequence_or_hash
 * migration_name
 * migration_type


# Migrations<a id="migrations"></a>

As far as dbgeni is concerned, a migration is a pair of files. One of the files contains SQL commands to make a change to the database, while the other file contains commands to reverse the operation. If one file contains a command to add a new table, then the other file should contain the equivalent drop table command. 

Sometimes it is not possible to reverse a database change if, for example, data was deleted, so it is possible to have an empty migration file that contains no commands.

The file that moves the database forward a version is known as the UP migration, while the one that performs the rollback is known as the DOWN migration.

For dbgeni to recognize migrations, they must be stored in the "migrations_directory" and named in a specific way:

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

A milestone is set by creating a file in the migrations\_directory, that has the name of the milestone as the filename and an extension of ".milestone". The file should contain the filename of the milestone migration on the first line and nothing else. For example, to set a milestone called release_1.0, with the migration 201101011754\_up\_create\_customer\_table.sql as the milestone, first create a file in the migrations directory:

    $ release_1.0.milestone

And the contents of the file:

    201101011754_up_create_customer_table.sql

You can use the [milestone generator](#generator_commands_milestone) to easily create milestones, and the [milestones](#milestone_commands) command to list any that exist.

    $ dbgeni milestones list

To apply or rollback all migrations to a particular milestone, use the migrations [apply](#migrations_apply_milestone) or [rollback](#migrations_rollback_milestone) back command, for example:

    $ dbgeni migrations apply    milestone <name_of_milestone>
    $ dbgeni migrations rollback milestone <name_of_milestone>

# DML Migrations<a id="dml_migrations"></a>

DML migrations are exactly the same as the migrations mentioned above, and the same set of commands are available, but replacing 'migrations' with 'dmls' in each case. The reason there are two places to store migrations is because a typical install workflow might be:

 * Create all the tables, indexes, sequences
 * Apply all the stored procedures
 * Load data, perhaps using the stored procedures

The idea behind DML migrations is to use them to store migration files that populate data into the tables. Using DML migrations is not essential, but it can simplify things if stored procedures are used to load or transform data as part of the install process.


# Stored Procedures<a id="stored_procedures"></a>

Many database applications make use of stored procedures and dbgeni can install them too. 

All code should be stored in the "code\_directory", and the naming of the files is important. The filename should be given the same name as the object name in the database. For example, if a code file creates a procedure called insert_customer, then the file should be called "insert\_customer.prc". In this case, the name of the file identifies the database object, and the file extension identifies the type of object.

There are 6 allowed file extensions:

 * pks - Package specification
 * pks - Package body
 * prc - Procedure
 * fnc - Function
 * trg - Trigger
 * typ - Oracle type definition

The naming of the files is very important for removing stored procedures, as the appropriate drop command will be generated from the filename, eg:

    insert_customer.prc => drop procedure insert_customer;
    insert_customer.fnc => drop function  insert_customer;

Ddbeni will also apply code files with the .sql extension. However, it is not recommended to store code in sql files, as dbgeni will no longer be able to generate the correct drop statement from the filename.

Dbgeni considers stored procedure code to be in one of two states:

 * Outstanding - This is code which has never been applied to the database, or has been changed since it was last applied.
 * Current - This is code that has been applied to the database, and has not been changed since it was last applied.

To determine if a code module is current, dbgeni generates a hash of the relevant file in the code_directory, and compares it to a hash that was stored in the dbgeni\_migrations table on the database. If the two match, then the code is considered current. 

If the code module is changed on the database manually or using another tool, then dbgeni will not see the change, and will still consider the module current.

## Installation Order<a id="stored_procedures_order"></a>

Outstanding procedure code is installed in alphabetical order based on the filename. For some applications this may be acceptable, but often one stored procedure depends on another, and the order of installation is important.

To control the order of installation a numeric prefix can be added to the procedure name. For example, if the application has two procedures:

 * check\_or\_install_customer.prc
 * install_customer.prc

Normally check\_or\_install\_customer will be installed first. However, if it depends on install\_customer, a numeric prefix can be added to the install\_customer.prc filename, forcing it to be installed first:

 * 001\_install\_customer.prc

If it is required to control install order, the numeric prefix can be any length, but it must end with an underscore character.


## Oracle Specific<a id="stored_procedures_oracle"></a>

When a code module is current, it does not necessarily mean it complied without error on the database. Unlike with migrations, dbgeni does not error if a code module compiles with errors. The reason is that Oracle packages and procedures can depend on one another so if a dependent procedure has not yet been installed, the current procedure will produce a compile error which will correct itself when the procedure is first used. Even if the procedure has a syntax error it is still stored in the database.

When coding a procedure, function, package or trigger for Oracle, the create or replace syntax should be used. The slash at the end of the procedur is optional, as dbgeni will add it if required. For example:

    create or replace procedure my_new_proc
    as
    begin
      null;
    end;
    /

Often permissions to execute the procedure need to be granted to various users after it is compiled. Such privileges can be included in the file along with the procedure. It is important to include the slash after the procedure definition if grants need to be specified. For example:

    create or replace procedure my_new_proc
    as
    begin
      null;
    end;
    /

    grant execute on my_new_proc to public;


## Mysql Specific<a id="stored_procedures_mysql"></a>

MySQL handles stored procedures differently from Oracle. If a procedure has a syntax error, it will not be installed on the database at all. However, if a procedure refers to another procedure or table that does not exist, MySQL will not error at compile time, and no errors will be reported. Therefore if errors are encountered when applying MySQL stored procedures, dbgeni will stop processing just like with migrations. The --force option can be used when applying code to force dbgeni to continue onto the next procedure if errors are encountered.

MySQL does not support the create or replace syntax, so any procedure code should include a block to optionally drop the procedure if it exists before recreating it. The MySQL delimiter should also be set appropriately. For example:

    delimiter $$
    drop procedure if exists proc1$$
    create procedure proc1
    begin
    end$$

## Sybase Specific<a id="stored_procedures_sybase"></a>

Sybase handles stored procedures similarly to Mysql. If a procedure has a syntax error, it will not be installed on the database at all. If a procedure refers to another procedure or table that does not exist, Sybase will also error at compile time and the procedure will not be installed onto the database. Therefore if errors are encountered when applying Sybase stored procedures, dbgeni will stop processing just like with migrations. The --force option can be used when applying code to force dbgeni to continue onto the next procedure if errors are encountered.

Sybase does not support the create or replace syntax, so any procedure code should include a block to optionally drop the procedure if it exists before recreating it. Any grants can be listed after the procedure definition. For example:

    if exists (select 1 from sysobjects
               where name = 'proc1'
               and type in ('P', 'TR'))
      drop proc proc1
    go

    create proc proc1()
    as
      return(1)
    go

    grant execute on proc1 to public
    go


## Generating Stored Procedure Files<a id="stored_procedures_generating"></a>

A dbgeni command can be used to create empty code files named in the correct way:

    $ dbgeni generate package   manage_customer
    $ dbgeni generate procedure insert_customer
    $ dbgeni generate function  select_customer
    $ dbgeni generate trigger   biud_on_customer
    $ dbgeni generate type      t_varchar2_tab

Each of these commands will create a file in the code\_directory with the correct name and some boiler plate code. In the case of a package, it will generate a file for each of the package specification and body. The code generated depends on the database\_type set in the config file.

Before the code can be applied to the database, the template file should be edited to contain valid code and then use the [code_commands](#code_commands) to apply it to the database.


# Logging<a id="logging"></a>

Each time dbgeni runs, it writes to a logfile called log.txt stored in the log directory. The log directory is created in the same directory as the .dbgeni config file and will be created automatically if it does not exist.

Each time a migration is applied or rolled back or a code module is applied, an additional log file is created with the same name as the migration file or code module file. This file contains all the input and output produced by the database when running the SQL statements. If dbgeni reports problems applying a migration, these log files are the place to look for errors. They are created in a sub-directory inside the log directory using a timestamp for the directory name, eg:

    20110922153123/201108101531_up_create_users.sql


# Plugins<a id="plugins"></a>

DBGeni provides all the functionality you need to install code and migrations, but sometimes projects need a more customized install, for example:

 * Run a check on a migration to ensure it does not contain certain types of DDL operations
 * Run a script to grant permissions on all procedures or tables after installation
 * Run a script to compile all objects in the schema after new stored procedures have been applied

## Hook Points<a id="plugins_hooks"></a>

DBGeni provides an interface to install plugins allowing a flexible way to customize the installation process. Plugins are defined in custom scripts and can be configured to run at various hook points:

 * before\_migration\_up       - run before each migration is applied
 * after\_migration\_up        - run after each migration is applied
 * before\_migration\_down     - run before each migration is removed
 * after\_migration\_down      - run after each migration is removed
 * before\_dml\_migration\_up   - run before each dml migration is applied
 * after\_dml\_migration\_up    - run after each dml migration is applied
 * before\_dml\_migration\_down - run before each dml migration is removed
 * after\_dml\_migration\_down  - run after each dml migration is removed
 * before\_code\_apply     - run before each code module is applied or modifed
 * after\_code\_apply      - run after each code module is applied or modified
 * before\_code\_remove    - run before each code module is removed
 * after\_code\_remove     - run after each code module is removed
 * before\_running\_migrations - run before any migrations are executed in a run of dbgeni, whether up or down
 * after\_running\_migrations  - run after any migrations are executed in a run of dbgeni, whether up or down
 * before\_running\_dml\_migrations - run before any dml migrations are executed in a run of dbgeni, whether up or down
 * after\_running\_dml\_migrations  - run after any dml migrations are executed in a run of dbgeni, whether up or down
 * before\_modifying\_code     - run before any code is changed in a run of dbgeni, whether adding or removing
 * after\_modifying\_code      - run after any code is changed in a run of dbgeni, whether adding or removing

## Enable Plugins<a id="plugins_enable"></a>

All plugins are stored in a directory and to enable plugins, the plugin_directory parameter needs to be in the config file:

    plugin_directory "./dbgeni_plugins"

When this config parameter is set, dbgeni will load any plugin files in finds in this directory.


## Coding Plugins<a id="plugins_coding"></a>

A dbgeni plugin is created using a standard Ruby class. There are only two requirements:

 1. The hook points must be defined in the class definition
 2. The class must implement a method called run that accepts two parameters

This is best illustrated with an example. The following code will implement a simple plugin that prints a message to the logfile and console.

    class DBGeni::Plugin::TestPlugin

      before_migration_up
      after_migration_up

      def run(hook, params)
        params[:logger].info "The plugin has been called from the hook: #{hook}"
      end
 
    end


While this is a very simple plugin, it illustrates most of the points required when creating any plugin.

The class name can be anything, but it is best to give it a namespace to avoid any clashes with existing dbgeni classes.

Next the hook points are defined. In this example, this plugin will fire before and after each migration is applied, but any of the hooks points mentioned above can be used.

Finally the run method is defined, expecting two parameters which will always be passed when the plugin is invoked:

 1. The name of the hook, ie before\_migration\_up or after\_migration\_up in this case.
 2. A hash of options relevant to the plugin.

For all hook points, the options hash will contain the following keys:

 * :logger - This is a reference to the dbgeni logger instance that is in use for the current dbgeni execution.
 * :object - This is a reference to the object the plugin refers to and is either a DBGeni::Code or DBGeni::Migration object, or in the case of before/after\_running\_migrations and before/after\_modifying\_code it contains a DBGeni::CodeList or DBGeni::MigrationList object which details all the code or migrations that are about to be applied.
 * :environment - This is a DBGeni::Environment object that contains all the parameters defined in the environment section of the config file
 * :connection - This contains a reference to the current database connection.

For \*\_running\_migrations and \*\_modifying\_code hooks, an additional parameter is passed:

 * :operation - This will contain either the text 'apply' or 'remove' depending if dbgeni is applying code and migrations or if it is removing code and rolling back migrations


With this set of parameters, the plugin can analyse the objects being applied to the DB, use the database connection, logger and various environment variables and use the full power of the Ruby programming language to achieve its goal.

## Aborting Execution<a id="plugins_abort"></a>

If a plugin completes processing cleanly and doesn't raise any exceptions, dbgeni will continue processing subsequent operations as normal. If the plugin discovers a reason processing should be stopped the dbgeni run can be aborted by raising a DBGeni::PluginException exception. If the plugin raises an unhandled exception, processing will also abort, but it is better practice to raise the defined exception.


## Order of Execution<a id="plugins_order"></a>

Plugins are loaded alphabetically based on their filename. If there are several plugins for one hook point, they will be executed in alphabetical filename order.


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

## dml migration<a id="generator_commands_dml_migration"></a>

The dml migration generator takes a single parameter, which is the name of a migration, and generates a pair of empty UP and DOWN migration files with the correct filenames:

    $ dbgeni generate dml_migration <name_of_migration>
    $ dbgeni generate dml <name_of_migration>

For example:

    $ dbgeni generate dml_migration create_users_table

    creating: /home/sodonnell/cool_project/./dml/201109221657_up_create_users_table.sql
    creating: /home/sodonnell/cool_project/./dml/201109221657_down_create_users_table.sql

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

### Sybase Specific<a id="migrations_sybase"></a>

For all other databases, if an error is encountered part way through a migration, dbgeni will stop processing. With Sybase, the isql client does not give any way to abort if an error is encountered. Therefore with Sybase, a migration file will alway run to the end, even if an error occurs in the file. DBGeni will stop after the migration if it detects any errors.

### apply all<a id="migrations_apply_all"></a>

To apply all migrations that are outstanding, use the all command, eg:

    $ dbgeni migrations apply all

If there are no outstanding migrations dbgeni will print a warning and exit cleanly, ie with a zero return value. If a problem is encountered applying a migration an error will be displayed and dbgeni exit with a non-zero value and stop processing.

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

To apply from the first outstanding migration to a milestone, use the milestone command, eg:

    $ dbgeni migrations apply milestone rel_1.0

The milestone command is similar to the until command, and it will apply outstanding migrations up to and including the migration specified in the milestone file.


### Forcing Migrations

Normally when applying migrations, if an error is raised by any SQL statement in the file, dbgeni stops processing immediately (see not above about Sybase) - it does not complete the current migration or move onto any subsequent ones. Sometimes you want to force a migration to complete, knowing some of the errors are not important. For all the migration commands, the --force (-f for short) switch can be specified with prevents dbgeni stopping when it encounters most errors, eg:

    $ dbgeni migrations apply all --force

## Rollback Migrations

When a migration is rolled back the contents of the DOWN script are applied to the target database. For rollbacks, the DOWN scripts are applied in *descending* TIMESTAMP order. There is a set of rollback commands that mirror the migration apply commands.

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

To rollback to a milestone, use the milestone command, eg:

    $ dbgeni migrations rollback milestone rel_1.0

As with the rollback until command, rolling back to a milestone will rollback from the last applied migration down to but NOT including the migration specified in the milestone file.

### Forcing Rollbacks

As with applying migrations, rollbacks can be forced through with the --force (-f for short) switch. This is particularly useful if an apply failed part way through and you want to clean up any changes it made without worrying about where the original migration failed.

    $ dbgeni migrations rollback all --force

# DML Migration Commands<a id="dml_migration_commands"></a>

All commands available for [migrations](#migration_commands) are available for DML migrations. In all the examples above, substitute dmls in place of migrations to use the DML Migration command. 

# Milestone Commands<a id="milestone_commands"></a>

The milestones command has only a single sub-command to list milestones. The --environment-name (-e) and --config-file (-c) switches can be used if necessary.

## list<a id="milestone_commands_list"></a>

To list all the milestones present in the migrations\_directory, use the list sub-command:

    $ dbgeni milestones list

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

If there is no outstanding code, dbgeni will print a warning and exit cleanly with a zero exit status..

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

### Forcing Code<a id="code_forcing"></a>

For both Mysql and Sybase, dbgeni can continue applying code files after an error by supplying the --force (-f for short) switch. For Oracle this is not necessary as a code compile error does not cause dbgeni to stop processing.

# Option Switches<a id="option_switches"></a>

Command line options allow the runtime behavior of dbgeni to be controlled.

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








