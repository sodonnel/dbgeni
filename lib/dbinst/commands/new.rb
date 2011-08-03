# Expects only one parameter, the directory of the new dbinst directory structure

ARGV << '--help' if ARGV.empty?

if ARGV.length > 1 or %w(-h --help).include? ARGV[0]
  puts "Error: only one parameter is allowed for the new command" if ARGV.length > 1
  puts <<-EOF
Usage: dbinst new <path/to/directory/for/new/installer/structure>
EOF
  exit
end

require 'fileutils'

directory = ARGV.shift

if File.directory?(directory)
  puts "Error: The directory already exists"
  exit
end

# create the base directory
begin
  puts "creating directory: #{directory}"
  FileUtils.mkdir_p(directory)
rescue Exception => e
  puts "error: failed to create #{directory} - #{e.to_s}"
  raise
end

# create the directory to hold migrations
begin
  puts "creating directory: #{directory}/migrations"
  FileUtils.mkdir_p(directory+'/migrations')
rescue Exception => e
  puts "error: failed to create #{directory}/migrations - #{e.to_s}"
  raise
end

# Create the initial version of the configuration file
begin
  puts "creating file: #{directory}/.dbinst"
  conf = File.open("#{directory}/.dbinst", "w")
  conf.puts <<-EOF

# This directory specifies the location of the migrations directory
migrations_directory "./migrations"

# Environment Section
#
# There must be at least one environment, and at a minimum each environment
# should define a username, database and password.
#
# Typically there will be more than one enviroment block detailling development,
# test and production but any number of environments are valid provided there is at least one.

# environment('development') {
#   username 'user'        # this must be here, or it will error
#   database 'DEV.WORLD'   # this must be here, or it will error. For Oracle, this is the TNS Name
#   password ''            # If this value is missing, it will be promoted for if the env is used.
#
#   Other parameters can be defined here and will override global_parameters
#   param_name 'value'
# }
#
# environment('test') {
#   username 'user'        # this must be here, or it will error
#   database 'TEST.WORLD'  # this must be here, or it will error. For Oracle, this is the TNS Name
#   password ''            # If this value is missing, it will be promoted for if the env is used.
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
  puts "error: failed to create #{directory}/.dbinst - #{e.to_s}"
end

