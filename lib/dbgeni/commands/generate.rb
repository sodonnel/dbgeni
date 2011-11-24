def usage
  puts <<-EOF
Usage:

The generate command is a helper to create appropriately named db migration
and code files.

Use --config-file to specify the config file to use. If none is specified
then a file called .dbgeni will be used if it is present in the current directory,
otherwise an error will be raised.

Usage:
dbgeni generate command parameters

The allowed commands are:

migration  Generates a set of files for a new database migration. The only parameter
           is a name for the migration:
             dbgeni generate migration name_for_this_migration

milestone  Generates a milestone, which is like a tag on a particular migration indicating
           that a migration completes a release of the application
             dbgenu generate milestone name_for_milestone existing_migration_for_milestone

package    Generates a pair of files for a plsql package with the given package name
             dbgeni generate package my_package_name

procedure  Generates a file for a plsql procedure with the given procedure name
             dbgeni generate procedure my_procedure_name

function   Generates a file for a plsql function with the given function name
             dbgeni generate function my_procedure_name

EOF
end

if %w(-h --help).include? ARGV[0]
  usage
  exit(0)
end

command = ARGV.shift
name    = ARGV.shift

unless name
  puts "error: You must specify a name for the #{command}"
  exit(1)
end

require 'fileutils'

config = DBGeni::Config.load_from_file($config_file)

case command
when 'migration', 'mig'
  datestamp = Time.now.strftime('%Y%m%d%H%M')
  %w(up down).each do |f|
    filename = File.join(config.migration_directory, "#{datestamp}_#{f}_#{name}.sql")
    puts "creating: #{filename}"
    FileUtils.touch(filename)
  end
when 'package', 'pkg'
  filename = File.join(config.code_dir, "#{name}.pks")
  if File.exists?(filename)
    puts "exists: #{filename}"
  else
    puts "creating: #{filename}"
    File.open(filename, 'w') do |f|
      f.puts "create or replace package #{name}"
      f.puts "as"
      f.puts "begin"
      f.puts ""
      f.puts "end #{name};"
      f.puts "/"
    end
  end
  filename = File.join(config.code_dir, "#{name}.pkb")
  if File.exists?(filename)
    puts "exists: #{filename}"
  else
    puts "creating: #{filename}"
    File.open(filename, 'w') do |f|
      f.puts "create or replace package body #{name}"
      f.puts "as"
      f.puts "begin"
      f.puts ""
      f.puts "end #{name};"
      f.puts "/"
    end
  end
when 'procedure', 'prc', 'proc'
  filename = File.join(config.code_dir, "#{name}.prc")
  if File.exists?(filename)
    puts "exists: #{filename}"
  else
    puts "creating: #{filename}"
    File.open(filename, 'w') do |f|
      if config.db_type == 'oracle'
        f.puts "create or replace procedure #{name}"
        f.puts "as"
        f.puts "begin"
        f.puts "  null;"
        f.puts "end #{name};"
        f.puts "/"
      elsif config.db_type == 'mysql'
        f.puts "deliminator $$"
        f.puts "drop procedure if exists #{name}$$"
        f.puts "create procedure #{name}()"
        f.puts "begin"
        f.puts "end$$"
      end

    end
  end
when 'function', 'fnc', 'func'
  filename = File.join(config.code_dir, "#{name}.fnc")
  if File.exists?(filename)
    puts "exists: #{filename}"
  else
    puts "creating: #{filename}"
    File.open(filename, 'w') do |f|
      if config.db_type == 'oracle'
        f.puts "create or replace function #{name}"
        f.puts "  return varchar2"
        f.puts "as"
        f.puts "begin"
        f.puts "  null;"
        f.puts "end #{name};"
        f.puts "/"
      elsif config.db_type == 'mysql'
        f.puts "deliminator $$"
        f.puts "drop function if exists #{name}$$"
        f.puts "create function #{name}()"
        f.puts "  returns varchar"
        f.puts "begin"
        f.puts "end$$"
      end
    end
  end
when 'trigger', 'trg'
  filename = File.join(config.code_dir, "#{name}.trg")
  if File.exists?(filename)
    puts "exists: #{filename}"
  else
    puts "creating: #{filename}"
    File.open(filename, 'w') do |f|
      if config.db_type == 'oracle'
        f.puts "create or replace trigger #{name} before insert on TABLE"
        f.puts "for each row"
        f.puts "begin"
        f.puts "  null;"
        f.puts "end;"
        f.puts "/"
      elsif config.db_type == 'mysql'
        f.puts "deliminator $$"
        f.puts "drop trigger if exists #{name}$$"
        f.puts "CREATE TRIGGER #{name} BEFORE INSERT ON TABLE"
        f.puts "FOR EACH ROW"
        f.puts "BEGIN"
        f.puts "END$$"
      end
    end
  end
when 'milestone'
  filename = File.join(config.migration_directory, "#{name}.milestone")
  if File.exists?(filename)
    puts "milestone already exists"
    exit(1)
  end
  # The migration can be either the migration filename, or the internal :: name
  migration = ARGV.shift
  unless migration
    puts "You must specify a migration for the milestone"
    exit(1)
  end
  if migration =~ /::/ # internal name
    migration = DBGeni::Migration.filename_from_internal_name(migration)
  end
  unless File.exists?(File.join(config.migration_directory, migration))
    puts "The migration #{migration} does not exist"
    exit(1)
  end
  File.open(filename, 'w') do |f|
    f.puts migration
  end
  puts "creating: #{filename}"
else
  puts "Error: #{command} is not a invalid generator"
  exit(1)
end

exit(0)
