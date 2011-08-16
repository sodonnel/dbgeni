ARGV << '--help' if ARGV.empty?

command = ARGV.shift

case command
  when 'new'
  require 'dbinst/commands/new'
  when 'initialize'
  require 'dbinst/commands/initialize'
  when 'config'
  require 'dbinst/commands/config'
  when 'generate'
  require 'dbinst/commands/generate'
  when 'migrations'
  require 'dbinst/commands/migrations'
  else
  puts "Error: Command not recognized" unless %w(-h --help).include?(command)
  puts <<-EOT
Usage: dbinst COMMAND [ARGS]

The available dbinst commands are:
  new        Generate a new default application directory structure
  initialize Create the dbinst_migrations table in the database
  config     List the current config for a given environment
  migrations List and Apply Migrations
  generate   Generate migrations and code files

All commands can be run with -h for more information.
EOT
end

