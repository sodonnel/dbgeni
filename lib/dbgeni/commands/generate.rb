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
  puts "error: You must specify a name for the migration"
  exit(1)
end

require 'dbgeni'
require 'fileutils'

config = DBGeni::Config.load_from_file($config_file)

case command
when 'migration'
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
    end
  end
when 'procedure', 'prc', 'proc'
  filename = File.join(config.code_dir, "#{name}.prc")
  if File.exists?(filename)
    puts "exists: #{filename}"
  else
    puts "creating: #{filename}"
    File.open(filename, 'w') do |f|
      f.puts "create or replace procedure #{name}"
      f.puts "as"
      f.puts "begin"
      f.puts "  null;"
      f.puts "end #{name};"
    end
  end
when 'function', 'fnc', 'func'
  filename = File.join(config.code_dir, "#{name}.prc")
  if File.exists?(filename)
    puts "exists: #{filename}"
  else
    puts "creating: #{filename}"
    File.open(filename, 'w') do |f|
      f.puts "create or replace function #{name}"
      f.puts "  return varchar2"
      f.puts "as"
      f.puts "begin"
      f.puts "  null;"
      f.puts "end #{name};"
    end
  end
end

exit(0)
