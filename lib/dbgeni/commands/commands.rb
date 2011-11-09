ARGV << '--help' if ARGV.empty?

$initial_command = ARGV.shift

case $initial_command
  when 'new', 'new-config'             ,'n'
  require 'dbgeni/commands/new'
  when 'initialize'                    ,'i'
  require 'dbgeni/commands/initialize'
  when 'config'
  require 'dbgeni/commands/config'
  when 'generate'                      ,'g'
  require 'dbgeni/commands/generate'
  when 'migrations'                    ,'m'
  require 'dbgeni/commands/migrations'
  when 'code'                          ,'c'
  require 'dbgeni/commands/code'
  when 'milestones'
  require 'dbgeni/commands/milestones'

  else
  puts "Error: Command not recognized" unless %w(-h --help).include?($initial_command)
  puts <<-EOT
Usage: dbgeni COMMAND [ARGS]

The available dbgeni commands are:
  new        Generate a new default application directory structure
  new-config Generate a templated config file in an existing directory
  initialize Create the dbgeni_migrations table in the database
  config     List the current config for a given environment
  migrations List and Apply Migrations
  code       List, compile and remove stored procedures
  generate   Generate migrations and code files

All commands can be run with -h for more information.
EOT
end

