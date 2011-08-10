def usage
  puts <<-EOF
Usage:

The generate command is a helper to create appropriately named db migration
and code files.

Use --config-file to specify the config file to use. If none is specified
then a file called .dbinst will be used if it is present in the current directory,
otherwise an error will be raised.

Usage:
dbinst generate command parameters

The allowed commands are:

migration  Generates a set of files for a new database migration. The only parameter
           is a name for the migration:
             dbinst generate migration name_for_this_migration

package    Generates a pair of files for a plsql package with the given package name
             dbinst generate package my_package_name

procedure  Generates a file for a plsql procedure with the given procedure name
             dbinst generate procedure my_procedure_name

function   Generates a file for a plsql function with the given function name
             dbinst generate function my_procedure_name

EOF
end

if %w(-h --help).include? ARGV[0]
  usage
  exit(0)
end

command = ARGV.shift
name    = ARGV.shift

unless name
  puts "error: all migrations must have a name\n"
  usage
  exit(1)
end

require 'dbinst'
require 'fileutils'

config = DBInst::Config.load_from_file($config_file)

case command
when 'migration'
  datestamp = Time.now.strftime('%Y%m%d%H%M')
  %w(up down verify).each do |f|
    filename = File.join(config.migration_directory, "#{datestamp}_#{f}_#{name}.sql")
    puts "creating: #{filename}"
    FileUtils.touch(filename)
  end
when 'package'
  puts "not implemented"
when 'procedure'
  puts "not implemented"
when 'function'
  puts "not implemented"
end

exit(0)
