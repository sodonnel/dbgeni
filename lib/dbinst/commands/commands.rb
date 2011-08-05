ARGV << '--help' if ARGV.empty?

command = ARGV.shift

case command
  when 'new'
  require 'dbinst/commands/new.rb'
  when 'initialize'

  when 'config'
  require 'dbinst/commands/config.rb'
  else
  puts "Error: Command not recognized" unless %w(-h --help).include?(command)
  puts <<-EOT
Usage: dbinst COMMAND [ARGS]

The available dbinst commands are:
  new        Generate a new default application directory structure
  initialize Create the dbinst_migrations table in the database
  config     List the current config for a given environment

All commands can be run with -h for more information.
EOT
end

