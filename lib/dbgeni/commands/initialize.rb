if %w(-h --help).include? ARGV[0]
  puts <<-EOF
Usage: dbgeni initialize <--environment-name env_name> <--config-file path/to/config> <--username user> <--password password>

If config-file is not specified, then a file called .dbgeni in the current directory will be
used if it exists, otherwise an error will occurr

If there is more than one environment defined in the config file, then environment-name must
be specified.

-e can be used as an abbreviation for --environment-name
-c can be used as an abbreviation for --config-file
-u can be used as an abbreviation for --username
-p can be used as an abbreviation for --password


EOF
  exit(0)
end

installer = $build_installer.call

begin
  logger = DBGeni::Logger.instance
  installer.initialize_database
  logger.info "Database initialized successfully"
rescue DBGeni::DatabaseAlreadyInitialized
  logger.error "The Database has already been initialized"
  exit(1)
rescue DBGeni::NoInitializerForDBType
  logger.error "There is no initializer for the db_type setting"
  exit(1)
rescue DBGeni::NoConnectorForDBType
  logger.error "There is no connector defined for the db_type setting"
  exit(1)
end

exit(0)



