if %w(-h --help).include? ARGV[0]
  puts <<-EOF
Usage: dbinst initialize <--environment-name env_name> <--config-file path/to/config>

If config-file is not specified, then a file called .dbinst in the current directory will be
used if it exists, otherwise an error will occurr

If there is more than one environment defined in the config file, then environment-name must
be specified.

-e can be used as an abbreviation for --environment-name
-c can be used as an abbreviation for --config-file

EOF
  exit(0)
end

require 'dbinst'

begin
  installer = DBInst::Base.installer_for_environment($config_file, $environment_name)
  installer.initialize_database
  puts "Database initialized successfully"
rescue DBInst::DatabaseAlreadyInitialized
  puts "error: The Database has already been Initialized"
  exit(1)
rescue DBInst::NoInitializerForDBType
  puts "error: There is no initializer for the db_type setting"
  exit(1)
rescue DBInst::NoConnectorForDBType
  puts "error: There is no connector defined for the db_type setting"
  exit(1)
end

exit(0)

