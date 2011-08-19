if %w(-h --help).include? ARGV[0]
  puts <<-EOF
Usage: dbgeni migrations command <--environment-name env_name> <--config-file path/to/config>

If config-file is not specified, then a file called .dbgeni in the current directory will be
used if it exists, otherwise an error will occurr

If there is more than one environment defined in the config file, then environment-name must
be specified.

-e can be used as an abbreviation for --environment-name
-c can be used as an abbreviation for --config-file

Avaliable commands are:

Readonly
--------

list        Prints out all available migrations
            dbgeni migrations list --config-file /home/myapp/.dbgeni

applied     Prints all migrations which have been applied to an environment
            dbgeni migrations applied --environment-name test --config-file /home/myapp/.dbgeni

outstanding Prints all migrations which have not been applied to an environment
            dbgeni migrations outstanding --environment-name test --config-file /home/myapp/.dbgeni


Destructive
-----------

apply       Apply migrations to the given environment. Can specify:

              all     Apply all outstanding migrations
              next    Apply only the next migration and stop
              specific migrations to apply

            dbgeni migrations apply all  --environment-name test --config-file /home/myapp/.dbgeni
            dbgeni migrations apply next --environment-name test --config-file /home/myapp/.dbgeni
            dbgeni migrations apply file1.sql file2.sql file6.sql --environment-name test --config-file /home/myapp/.dbgeni

EOF
  exit
end

require 'dbgeni'
command = ARGV.shift

installer = DBGeni::Base.installer_for_environment($config_file, $environment_name)

case command
when 'list'
  migrations = installer.migrations
  if migrations.length == 0
    puts "There are no migrations in #{installer.config.migration_directory}"
  end
  migrations.each do |m|
    puts m.to_s
  end
when 'applied'
  applied = installer.applied_migrations
  if applied.length == 0
    puts "There are no applied migrations in #{installer.config.migration_directory}"
  end
  applied.each do |m|
    puts m.to_s
  end
when 'outstanding'
  outstanding = installer.outstanding_migrations
  if outstanding.length == 0
    puts "There are no applied migrations in #{installer.config.migration_directory}"
  end
  outstanding.each do |m|
    puts m.to_s
  end
when 'apply'
  sub_command = ARGV.shift
  case sub_command
  when 'all'
    begin
      installer.apply_all_migrations
    rescue DBGeni::NoOutstandingMigrations
      puts "There are no outstanding migrations to apply"
    rescue DBGeni::MigrationApplyFailed
      puts "There was a problem applying a migration"
    end
  when 'next'
    begin
      installer.apply_next_migration
    rescue DBGeni::NoOutstandingMigrations
      puts "There are no outstanding migrations to apply"
    rescue DBGeni::MigrationApplyFailed
      puts "There was a problem applying a migration"
    end
 # when ~= /\.sql$/
  else
    puts "error: #{sub_command} is not a valid command"
  end

else
  puts "error: #{command} is not a valid command"
end

exit(0)



