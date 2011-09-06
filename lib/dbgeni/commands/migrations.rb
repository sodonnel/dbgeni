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
            dbgeni migrations apply YYYYMMDDHHMM::Name1 YYYYMMDDHHMM::Name2 YYYYMMDDHHMM::Name3 --environment-name test --config-file /home/myapp/.dbgeni

rollback    Run the rollback script for a given migration. Can specify:

            all       Rollback everything that has even been applied
            last      Rollback the last migration applied
            specific migrations to rollback

            dbgeni migrations rollback all  --environment-name test --config-file /home/myapp/.dbgeni
            dbgeni migrations rollback last --environment-name test --config-file /home/myapp/.dbgeni
            dbgeni migrations rollback YYYYMMDDHHMM::Name1 YYYYMMDDHHMM::Name2 YYYYMMDDHHMM::Name3 --environment-name test --config-file /home/myapp/.dbgeni

EOF
  exit
end

require 'dbgeni'

command = ARGV.shift

installer = DBGeni::Base.installer_for_environment($config_file, $environment_name)
logger    = DBGeni::Logger.instance

case command
when 'list'
  migrations = installer.migrations
  if migrations.length == 0
    logger.info "There are no migrations in #{installer.config.migration_directory}"
  end
  migrations.each do |m|
    puts m.to_s
  end
when 'applied'
  applied = installer.applied_migrations
  if applied.length == 0
    logger.info "There are no applied migrations in #{installer.config.migration_directory}"
  end
  applied.each do |m|
    puts m.to_s
  end
when 'outstanding'
  outstanding = installer.outstanding_migrations
  if outstanding.length == 0
    logger.info "There are no applied migrations in #{installer.config.migration_directory}"
  end
  outstanding.each do |m|
    puts m.to_s
  end

when 'apply'
  sub_command = ARGV.shift
  begin
    case sub_command
    when 'all'
      installer.apply_all_migrations
    when 'next'
      installer.apply_next_migration
    when /^(\d{12})::/
      # The param list are specific migration files, but in the internal format. One is
      # stored in sub_command and the rest are in ARGV. Grab all params that match the
      # parameter name format
      files = ARGV.select{ |f| f =~ /^(\d{12})::/ }
      files.unshift sub_command
      migrations = files.map {|f| DBGeni::Migration.initialize_from_internal_name(installer.config.migration_directory, f)}
      # Now attempt to run each migration ... forwards for apply
      migrations.sort{|x,y| x.migration_file <=> y.migration_file}.each do |m|
        installer.apply_migration(m)
      end
    else
      logger.error "#{sub_command} is not a valid command"
    end
  rescue DBGeni::NoOutstandingMigrations => e
    logger.error "There are no outstanding migrations to apply"
  rescue DBGeni::MigrationApplyFailed => e
    logger.error "There was a problem applying #{e.to_s}"
  rescue DBGeni::MigrationAlreadyApplied => e
    logger.error "The migration is already applied #{e.to_s}"
  end

when 'rollback'
  sub_command = ARGV.shift
  begin
    case sub_command
    when 'all'
      installer.rollback_all_migrations
    when 'last'
      installer.rollback_last_migration
    when /^(\d{12})::/
      # The param list are specific migration files, but in the internal format. One is
      # stored in sub_command and the rest are in ARGV. Grab all params that match the
      # parameter name format
      files = ARGV.select{ |f| f =~ /^(\d{12})::/ }
      files.unshift sub_command
      migrations = files.map {|f| DBGeni::Migration.initialize_from_internal_name(installer.config.migration_directory, f)}
      # Now attempt to run each migration ... backwards for rollback
      migrations.sort{|x,y| y.migration_file <=> x.migration_file}.each do |m|
        installer.rollback_migration(m)
      end
    else
      logger.error "#{sub_command} is not a valid command"
    end
  rescue DBGeni::NoAppliedMigrations => e
    logger.error "There are no applied migrations to rollback"
  rescue DBGeni::MigrationApplyFailed => e
    logger.error "There was a problem rolling back #{e.to_s}"
  rescue DBGeni::MigrationNotApplied
    logger.error "#{e.to_s} has not been applied so cannot be rolledback"
  end
else
  logger.error "#{command} is not a valid command"
end

exit(0)



