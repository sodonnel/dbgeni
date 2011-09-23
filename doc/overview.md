# Database Applications

A database and an application that uses it are both very similar and very different. Both are created from code - for the database, the code is applied to it, creating tables and indexes. In contrast the application code is compiled into a binary image or executable.

When a new version of an application is required, the old binary image is thrown away, but this is not what happens to a database - it is migrated from one version to the next by *Migration Scripts*.

DBGeni is a tool to help manage these migrations, applying and rolling them back to move your database from version to version easily.

Once you understand how much more reliable things become using migrations instead of schema compare and generator scripts, you will never want to use GUI tools to create schema objects again!

## DBGeni?

DBGeni is short for Database Generic Installer - it a nutshell, it installs *stuff* into your database, provided you follow a few somewhat opinionated rules.


## The Rules are all about Migrations

Imagine you have an empty database. 

The first version of the application only needs a single table, USERS.

So you create a script called create\_users.sql and in it put all the data definition (DDL) code to create the USERS table.

To get the USERS table onto the development, test or production database, all you need to do is apply the create\_users.sql script to the database, *migrating* it forward to version 1.

Later, you discover version 2 of the application needs another table, USER\_ASSETS, so you do the sensible thing, and create a new script called create\_user\_assets.sql and apply that *outstanding migration* to development, test and eventually production, moving the database from version 1 to version 2.

Provided each change or group of related changes is stored in a seperate migration script, moving the database between versions is a trivial task, assuming you know which migrations have not yet been applied, and in what order to apply them.

## Smarter Migrations

Database migrations generally need to be executed in the same order they were created, so if there was some way of knowing when a migration was created, then most of the time they can be applied in order, with the oldest first. Instead of calling the first migration create\_users.sql, put a date stamp at the start of the filename, in the format YYYYMMDDHHMI (and do the same for the second migration):

    201108101531_create_users.sql
    201108221024_create_user_assets.sql

By sorting the migrations in alphabetical order, it is easy to figure out in which order to apply them.

Now all that remains is to figure out which migrations have not yet been applied or are *outstanding*. The simple solution is to create a table in the database and use it to store the name of any migration that has been applied.

If the order the migrations must be applied is easily derived, and the outstanding migrations can be identified, then an installer can be used to apply the migrations to the database. This is the role of DBGeni.

## When things go wrong

Sometimes the new version of an application doesn't work as intended and needs to be *rolled back*. For the application this is easy - just start using the old version. For the database it is more difficult - it has already been migrated forward. The only way to get it back to the old version is to *rollback* the migration using a rollback script that does the opposite of the migration. 

In this case it would be a script that drops the USERS table and another script that drops the USER\_ASSETS table. 

As all releases should have a tested way of rolling back, it is good practice to create database change scripts in pairs, one to migrate the database forward, or move it up a version and one to rollback or move it down a version. Extending the naming convention for migrations we get two files per migration named like the following:

    201108101531_up_create_users.sql
    201108101531_down_create_users.sql


## So what exactly is DBGeni?

DBGeni is an installer. 

If you name your database migration scripts as described here, and allow DBGeni to create a table in your database to track applied migrations, it can be used to apply, track and rollback all your database migrations easily.

DBGeni is distributed as a Ruby Gem, and it should work anywhere Ruby runs. It has been tested on Windows 7, OS X and Linux on Ruby version 1.8.7 and 1.9.2.

DBGeni is normally used via it's command line interface which will be available after installing the gem, but more complex install scripts can be created if necessary.

## Why use DBGeni?

If your current Database release process requires a lot of manual work, or is error prone, or you have lots of environments to apply changes to, DBGeni might help you.

It only takes 2 minutes to try it out, so download DBGeni and play around.







