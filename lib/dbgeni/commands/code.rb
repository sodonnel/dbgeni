if %w(-h --help).include? ARGV[0]
  puts <<-EOF
Usage: dbgeni code command <--environment-name env_name> <--config-file path/to/config> <--force>

If config-file is not specified, then a file called .dbgeni in the current directory will be
used if it exists, otherwise an error will occurr

If there is more than one environment defined in the config file, then environment-name must
be specified.

If --force is specified, all code files will be compiled and be marked as Completed even
if errors occur.

-e can be used as an abbreviation for --environment-name
-c can be used as an abbreviation for --config-file
-f can be used as an abbreviation for --force


Avaliable commands are:

Readonly
--------

list        Prints out all available code modules
            dbgeni code list --config-file /home/myapp/.dbgeni

applied     Prints all code modules that have been applied to an environment
            dbgeni code applied --environment-name test --config-file /home/myapp/.dbgeni

outstanding Prints all code modules that have not been applied to an environment
            dbgeni code outstanding --environment-name test --config-file /home/myapp/.dbgeni


Destructive
-----------

apply       Apply code modules to the given environment. Can specify:

              all     Apply all code modules, even if they have already been applied.
              changed Apply only code modules that have changed since they were last applied
              specific code modules to apply

            dbgeni code apply all     --environment-name test --config-file /home/myapp/.dbgeni <--force>
            dbgeni code apply changed --environment-name test --config-file /home/myapp/.dbgeni <--force>
            dbgeni code apply insert_t1_proc.prc admin_package.pkb --environment-name test --config-file /home/myapp/.dbgeni <--force>

remove      Remove code modules from the given environment. Can specify:

            all      Remove all code modules installed
            specific code modules to remove

            dbgeni code remove all  --environment-name test --config-file /home/myapp/.dbgeni <--force>
            dbgeni code remove insert_t1_proc.prc admin_package.pkb --environment-name test --config-file /home/myapp/.dbgeni <--force>

EOF
  exit
end

require 'dbgeni'

command = ARGV.shift

installer = nil
begin
  installer = DBGeni::Base.installer_for_environment($config_file, $environment_name)
rescue DBGeni::ConfigSyntaxError => e
  puts "There is an error in the config file: #{e.to_s}"
  exit(1)
rescue DBGeni::ConfigFileNotExist => e
  puts "The config file #{$config_file} does not exist: #{e.to_s}"
  exit(1)
rescue DBGeni::ConfigFileNotSpecified => e
  puts "No config file was specified"
  exit(1)
rescue DBGeni::ConfigAmbiguousEnvironment => e
  puts "No environment specified and config file defines more than one environment"
  exit(1)
rescue DBGeni::EnvironmentNotExist => e
  puts "The environment #{$environment_name} does not exist"
  exit(1)
end

logger    = DBGeni::Logger.instance

begin
  case command
  when 'list'
  when 'applied'
  when 'outstanding'
  when 'apply'
    sub_command = ARGV.shift
    case sub_command
    when 'all'
    when 'changed'
    when /^(\d{12})::/
    else
      logger.error "#{sub_command} is not a valid command"
    end

  when 'remove'
    sub_command = ARGV.shift
    case sub_command
    when 'all'
    when /^(\d{12})::/
    else
      logger.error "#{sub_command} is not a valid command"
    end
  else
    logger.error "#{command} is not a valid command"
  end
rescue DBGeni::NoOutstandingMigrations => e
  logger.error "There are no outstanding migrations to apply"
  exit(1)
rescue DBGeni::MigrationApplyFailed => e
  logger.error "There was a problem #{command == 'rollback' ? 'rolling back' : 'applying' } #{e.to_s}"
  exit(1)
rescue DBGeni::MigrationAlreadyApplied => e
  logger.error "The migration is already applied #{e.to_s}"
  exit(1)
rescue DBGeni::MigrationFileNotExist => e
  logger.error "The migration file, #{e.to_s} does not exist"
  exit(1)
rescue DBGeni:: DatabaseNotInitialized => e
  logger.error "The database needs to be initialized with the command dbgeni initialize"
  exit(1)
rescue DBGeni::NoAppliedMigrations => e
  logger.error "There are no applied migrations to rollback"
  exit(1)
rescue DBGeni::MigrationNotApplied
  logger.error "#{e.to_s} has not been applied so cannot be rolledback"
  exit(1)
rescue DBGeni::MigrationNotOutstanding
  logger.error "#{e.to_s} does not exist or is not outstanding"
  exit(1)
end


exit(0)
