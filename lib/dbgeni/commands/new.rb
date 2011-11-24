# Expects only one parameter, the directory of the new dbgeni directory structure

ARGV << '--help' if ARGV.empty?

if ARGV.length > 1 or %w(-h --help).include? ARGV[0]
  puts "Error: only one parameter is allowed for the new command" if ARGV.length > 1
  puts <<-EOF
Usage: dbgeni new <path/to/directory/for/new/installer/structure>
EOF
  exit
end

require 'fileutils'

directory = ARGV.shift

# There can be two commands here - first is to create the directory
# structure, the second is new-conf to just create the file, but only if
# the directory exists.
if %w(n new).include? $initial_command
  if File.directory?(directory)
    puts "Error: The directory already exists"
    exit(1)
  end

  # create the base directory
  begin
    puts "creating directory: #{directory}"
    FileUtils.mkdir_p(directory)
  rescue Exception => e
    puts "error: failed to create #{directory} - #{e.to_s}"
    exit(1)
  end

  # create the directory to hold migrations
  begin
    puts "creating directory: #{directory}/migrations"
    FileUtils.mkdir_p(directory+'/migrations')
  rescue Exception => e
    puts "error: failed to create #{directory}/migrations - #{e.to_s}"
    exit(1)
  end
  # create the directory to hold code
  begin
    puts "creating directory: #{directory}/code"
    FileUtils.mkdir_p(directory+'/code')
  rescue Exception => e
    puts "error: failed to create #{directory}/code - #{e.to_s}"
    exit(1)
  end

else
  unless File.directory?(directory)
    puts "Error: The directory #{directory} does not exist"
    exit(1)
  end
end


# Create the initial version of the configuration file
begin
  puts "creating file: #{directory}/.dbgeni"
  conf = File.open("#{directory}/.dbgeni", "w")
  conf.puts <<-EOF

# This directory specifies the location of the migrations directory
migrations_directory "./migrations"

# This directory specifies the location of any code modules
code_directory "./code"

# This specifies the type of database this installer is applied against
# Valid values are oracle, mysql, sqlite however this is not validated
# to enable different database plugins to easily be added.
database_type "sqlite"

# This is the table the installer logs applied migrations in the database
# The default is dbgeni_migrations
database_table "dbgeni_migrations"


# Environment Section
#
# There must be at least one environment, and at a minimum each environment
# should define a username, database and password.
#
# Typically there will be more than one enviroment block detailling development,
# test and production but any number of environments are valid provided there is at least one.

environment('development') {

   database 'testdb.sqlite' # this must be here, or it will error. For Oracle, this is the TNS Name
                            # for mysql this is the database selected after logon by the 'use database'
                            # command. For Sqlite, this is the filename of the database
#   username ''             # this must be here, or it will error (unless using sqlite)
#   password ''             # If this value is missing, it will be promoted for if needed
#   hostname '127.0.0.1'    # For mysql, specify the ip or hostname the server is running on.
                            # If it is running on localhost, use 127.0.0.1 - not localhost
#   port     '3306'         # For mysql, this specifies the port the server is running on, eg 3306
#
#   Other parameters can be defined here and will override global_parameters
#   param_name 'value'
}

#
# environment('test') {
#   username 'user'        # this must be here, or it will error
#   database 'TEST.WORLD'  # this must be here, or it will error. For Oracle, this is the TNS Name
#   password ''            # If this value is missing, it will be promoted for if needed.
# }
#
#
# Global Parameters
#
# There can only be one Global Parameter block.
#
# This is used to define parameters that are common to all environments.
# If the parameter is redefined in an environment block, then the value in the environment block
# overrides the global parameter.
#
# global_parameters { # These are common parameters to all environments, but they can be
#                     # overriden. Basically take global, merge in environment
#   param_name 'value'
# }

EOF
rescue Exception => e
  puts "error: failed to create #{directory}/.dbgeni - #{e.to_s}"
  exit(1)
end

exit(0)
