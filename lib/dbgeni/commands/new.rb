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

# This specifes the location of the plugin directory. Specifying this parameter
# enables plugins and the directory must exist
# plugin_directory "./dbgeni_plugins"

# This specifies the type of database this installer is applied against
# Valid values are oracle, mysql, sqlite, sybase however this is not validated
# to enable different database plugins to easily be added.
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
# Typically there will be more than one enviroment block detailling development,
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
#  install_schema 'other' # Optional: If dbgeni connects as a database user, but the application is owned
                          # by another user, set the application schema here

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

#
# environment('test') {
#   username 'user'
#   database 'TEST.WORLD'
#   password ''
# }
#


EOF
rescue Exception => e
  puts "error: failed to create #{directory}/.dbgeni - #{e.to_s}"
  exit(1)
end

exit(0)
