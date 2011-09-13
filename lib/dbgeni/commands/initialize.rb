if %w(-h --help).include? ARGV[0]
  puts <<-EOF
Usage: dbgeni initialize <--environment-name env_name> <--config-file path/to/config>

If config-file is not specified, then a file called .dbgeni in the current directory will be
used if it exists, otherwise an error will occurr

If there is more than one environment defined in the config file, then environment-name must
be specified.

-e can be used as an abbreviation for --environment-name
-c can be used as an abbreviation for --config-file

EOF
  exit(0)
end

require 'dbgeni'

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
end

begin
  logger = DBGeni::Logger.instance
  installer.initialize_database
  logger.info "Database initialized successfully"
rescue DBGeni::DatabaseAlreadyInitialized
  logger.error "The Database has already been Initialized"
  exit(1)
rescue DBGeni::NoInitializerForDBType
  logger.error "There is no initializer for the db_type setting"
  exit(1)
rescue DBGeni::NoConnectorForDBType
  logger.error "There is no connector defined for the db_type setting"
  exit(1)
end

exit(0)



