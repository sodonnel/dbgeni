# 0.7.0

13th May 2012

Download: [dbgeni-0.7.0.gem](/downloads/dbgeni-0.7.0.gem)

 * Allow current schema to be set for Oracle installs
 * Added support for Oracle types and code files with .sql extension
 * Enhanced config loader be more flexible
 * Added utility methods to make dbgeni scriptable
   * Changed the logger to use absolute paths for logfiles
   * Added the database_initialized? method to base


# 0.6.1

1st March 2012

Download: [dbgeni-0.6.0.gem](/downloads/dbgeni-0.6.1.gem)

 * Fix issue where code file hashes different between Windows and Linux

# 0.6.0

27th February 2012

Download: [dbgeni-0.6.0.gem](/downloads/dbgeni-0.6.0.gem)

 * Reprompt for password If a blank string is supplied
 * Don't echo password to screen when entering password (not windows)
 * Ability to include another config file into the current config file
 * Exit with a zero status when 'migration apply outstanding' and 'code apply outstanding' have nothing to do

# 0.5.0

4th February 2012

Download: [dbgeni-0.5.0.gem](/downloads/dbgeni-0.5.0.gem)

 * Removed the dbi and dbd dependencies for Sybase
 * Allow a prefix to be given to code files to control install order


# 0.4.0

15th January 2012

Download: [dbgeni-0.4.0.gem](/downloads/dbgeni-0.4.0.gem)

 * Sybase support (JRuby only)
 * Force code applies on error in Mysql and Sybase
 * Remove DOS line endings from files before executing

# 0.3.0 

24th November 2011

Download: [dbgeni-0.3.0.gem](/downloads/dbgeni-0.3.0.gem)

 * MySQL migrations support
 * MySQL stored procedure support
 * Experimental JRuby support for sqlite only and using --1.9 switch

# 0.2.0

Download: [dbgeni-0.2.0.gem](/downloads/dbgeni-0.2.0.gem)

 * Support for Oracle stored procedures
 * Better error messaging if the DB CLI is not installed
 * Better organisation of logfiles into timestamped directories
 * Milestone support
 * Prompt for password if it is left blank in the config file

# 0.1.0

Download: [dbgeni-0.1.0.gem](/downloads/dbgeni-0.1.0.gem)

 * Support for Sqlite and Oracle
 * Support for many environments
 * Support for SQL migration files
 * Complete command line interface

# Feature Backlog

These are some of the features I have planned. If you have an idea for a feature let me know at stephen dot odonnell at gmail.com - I cannot guarantee I will add it, but if it makes sense I will.

 * Parameters in SQL files
 * DAT files to load data
 * Support for other databases (SQL Server, Postgres, ...)
 * Validation scripts
 * Pre and post migration hooks

