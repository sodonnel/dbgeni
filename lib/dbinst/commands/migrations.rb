if %w(-h --help).include? ARGV[0]
  puts <<-EOF
Usage: dbinst migrations command <--environment-name env_name> <--config-file path/to/config>

If config-file is not specified, then a file called .dbinst in the current directory will be
used if it exists, otherwise an error will occurr

If there is more than one environment defined in the config file, then environment-name must
be specified.

-e can be used as an abbreviation for --environment-name
-c can be used as an abbreviation for --config-file

Avaliable commands are:

Readonly
--------

list        Prints out all available migrations
            dbinst migrations list --config-file /home/myapp/.dbinst

applied     Prints all migrations which have been applied to an environment
            dbinst migrations applied --environment-name test --config-file /home/myapp/.dbinst

outstanding Prints all migrations which have not been applied to an environment
            dbinst migrations outstanding --environment-name test --config-file /home/myapp/.dbinst


Destructive
-----------

apply       Apply migrations to the given environment. Can specify:

              all     Apply all outstanding migrations
              next    Apply only the next migration and stop
              specific migrations to apply

            dbinst migrations apply all  --environment-name test --config-file /home/myapp/.dbinst
            dbinst migrations apply next --environment-name test --config-file /home/myapp/.dbinst
            dbinst migrations apply file1.sql file2.sql file6.sql --environment-name test --config-file /home/myapp/.dbinst

EOF
  exit
end

require 'dbinst'
command = ARGV.shift

installer = DBInst::Base.installer_for_environment($config_file, $environment_name)

case command
when 'list'
  migrations = installer.migrations
  if migrations.length
    puts "There are no migrations in #{installer.config.migration_directory}"
  end
  migrations.each do |m|
    puts m.to_s
  end
when 'applied'

when 'outstanding'

else
  puts "error: #{command} is not a valid command"
end

exit(0)



