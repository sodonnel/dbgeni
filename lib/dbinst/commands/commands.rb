ARGV << '--help' if ARGV.empty?

command = ARGV.shift

case command
  when 'new'
  require 'dbgeni/commands/new'
  when 'initialize'
  require 'dbgeni/commands/initialize'
  when 'config'
  require 'dbgeni/commands/config'
  when 'generate'
  require 'dbgeni/commands/generate'
  when 'migrations'
  require 'dbgeni/commands/migrations'
  else
  puts "Error: Command not recognized" unless %w(-h --help).include?(command)
  puts <<-EOT
Usage: dbgeni COMMAND [ARGS]

The available dbgeni commands are:
  new        Generate a new default application directory structure
  initialize Create the dbgeni_migrations table in the database
  config     List the current config for a given environment
  migrations List and Apply Migrations
  generate   Generate migrations and code files

All commands can be run with -h for more information.
EOT
end

