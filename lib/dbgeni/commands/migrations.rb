if %w(-h --help).include? ARGV[0]
  puts <<-EOF
Usage: dbgeni migrations command <--environment-name env_name> <--config-file path/to/config> <--force> <--username user> <--password password>

If config-file is not specified, then a file called .dbgeni in the current directory will be
used if it exists, otherwise an error will occurr

If there is more than one environment defined in the config file, then environment-name must
be specified.

If --force is specified, the migration will run to completion and be marked as Completed even
if errors occur.

-e can be used as an abbreviation for --environment-name
-c can be used as an abbreviation for --config-file
-f can be used as an abbreviation for --force
-u can be used as an abbreviation for --username
-p can be used as an abbreviation for --password


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

              all       Apply all outstanding migrations
              next      Apply only the next migration and stop
              until     Apply upto and including the specified migration
              specific migrations to apply
              milestone Apply upto a specified milestone

            dbgeni migrations apply all  --environment-name test --config-file /home/myapp/.dbgeni <--force>
            dbgeni migrations apply next --environment-name test --config-file /home/myapp/.dbgeni <--force>
            dbgeni migrations apply until YYYYMMDDHHMM::Name1 --environment-name test --config-file /home/myapp/.dbgeni <--force>
            dbgeni migrations apply YYYYMMDDHHMM::Name1 YYYYMMDDHHMM::Name2 YYYYMMDDHHMM::Name3 --environment-name test --config-file /home/myapp/.dbgeni <--force>
            dbgeni migrations apply milestone release_1.0 --environment-name test --config-file /home/myapp/.dbgeni <--force>

rollback    Run the rollback script for a given migration. Can specify:

            all       Rollback everything that has even been applied
            last      Rollback the last migration applied
            until     Rollback from the last applied migration until and including the specified migration
            specific migrations to rollback

            dbgeni migrations rollback all  --environment-name test --config-file /home/myapp/.dbgeni <--force>
            dbgeni migrations rollback last --environment-name test --config-file /home/myapp/.dbgeni <--force>
            dbgeni migrations rollback until YYYYMMDDHHMM::Name1 --environment-name test --config-file /home/myapp/.dbgeni <--force>
            dbgeni migrations rollback YYYYMMDDHHMM::Name1 YYYYMMDDHHMM::Name2 YYYYMMDDHHMM::Name3 --environment-name test --config-file /home/myapp/.dbgeni <--force>
            dbgeni migrations rollback milestone release_1.0 --environment-name test --config-file /home/myapp/.dbgeni <--force>

EOF
  exit
end

command = ARGV.shift

installer = nil
installer = $build_installer.call

logger    = DBGeni::Logger.instance

begin
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
      logger.info "There are no outstanding migrations in #{installer.config.migration_directory}"
    end
    outstanding.each do |m|
      puts m.to_s
    end

  when 'apply'
    sub_command = ARGV.shift
    case sub_command
    when 'all'
      installer.apply_all_migrations($force)
    when 'next'
      installer.apply_next_migration($force)
    when 'until', 'milestone'
      migration_name = nil
      if sub_command == 'milestone'
        unless ARGV[0]
          logger.error "A milestone must be specified"
          exit(1)
        end
        unless File.exists? File.join(installer.config.migration_directory, "#{ARGV[0]}.milestone")
          logger.error "The milestone #{ARGV[0]} does not exist"
          exit(1)
        end
        migration_name = DBGeni::Migration.internal_name_from_filename(
                            DBGeni::Migration.get_milestone_migration(
                              installer.config.migration_directory, "#{ARGV[0]}.milestone"))
      else
        # a migration name needs to be the next parameter
        migration_name = ARGV[0]
      end

      unless migration_name
        logger.error "A migration name must be specified"
        exit(1)
      end
      # and the migration needs to be in the correct format
      unless migration_name =~ /^(\d{12})::/
        logger.error "#{migration_name} is not a valid migration name"
        exit(1)
      end
      installer.apply_until_migration(migration_name, $force)
    when /^(\d{12})::/
      # The param list are specific migration files, but in the internal format. One is
      # stored in sub_command and the rest are in ARGV. Grab all params that match the
      # parameter name format
      files = ARGV.select{ |f| f =~ /^(\d{12})::/ }
      files.unshift sub_command
      installer.apply_list_of_migrations(files, $force)
    else
      logger.error "#{sub_command} is not a valid command"
    end

  when 'rollback'
    sub_command = ARGV.shift
    case sub_command
    when 'all'
      installer.rollback_all_migrations($force)
    when 'last'
      installer.rollback_last_migration($force)
    when 'until', 'milestone'
      migration_name = nil
      if sub_command == 'milestone'
        unless ARGV[0]
          logger.error "You must specify a milestone"
          exit(1)
        end
        unless File.exists? File.join(installer.config.migration_directory, "#{ARGV[0]}.milestone")
          logger.error "The milestone #{ARGV[0]} does not exist"
          exit(1)
        end
        migration_name = DBGeni::Migration.internal_name_from_filename(
                            DBGeni::Migration.get_milestone_migration(
                              installer.config.migration_directory, "#{ARGV[0]}.milestone"))
      else
        # a migration name needs to be the next parameter
        migration_name = ARGV[0]
      end

      unless migration_name
        logger.error "A migration name must be specified"
        exit(1)
      end
      # and the migration needs to be in the correct format
      unless migration_name =~ /^(\d{12})::/
        logger.error "#{migration_name} is not a valid migration name"
        exit(1)
      end
      installer.rollback_until_migration(migration_name, $force)
    when /^(\d{12})::/
      # The param list are specific migration files, but in the internal format. One is
      # stored in sub_command and the rest are in ARGV. Grab all params that match the
      # parameter name format
      files = ARGV.select{ |f| f =~ /^(\d{12})::/ }
      files.unshift sub_command
      installer.rollback_list_of_migrations(files, $force)
#      migrations = files.map {|f| DBGeni::Migration.initialize_from_internal_name(installer.config.migration_directory, f)}
#      # Now attempt to run each migration ... backwards for rollback
#      migrations.sort{|x,y| y.migration_file <=> x.migration_file}.each do |m|
#        installer.rollback_migration(m, $force)
#      end
    else
      logger.error "#{sub_command} is not a valid command"
    end
  else
    logger.error "#{command} is not a valid command"
  end
rescue DBGeni::NoOutstandingMigrations => e
  logger.info "There are no outstanding migrations to apply"
  exit(0)
rescue DBGeni::MigrationApplyFailed => e
  logger.error "There was a problem #{command == 'rollback' ? 'rolling back' : 'applying' } #{e.to_s}"
  exit(1)
rescue DBGeni::MigrationAlreadyApplied => e
  logger.error "The migration is already applied #{e.to_s}"
  exit(1)
rescue DBGeni::MigrationFileNotExist => e
  logger.error "The migration file #{e.to_s} does not exist"
  exit(1)
rescue DBGeni:: DatabaseNotInitialized => e
  logger.error "The database needs to be initialized with the command dbgeni initialize"
  exit(1)
rescue DBGeni::NoAppliedMigrations => e
  logger.error "There are no applied migrations to rollback"
  exit(1)
rescue DBGeni::MigrationNotApplied => e
  logger.error "#{e.to_s} has not been applied so cannot be rolledback"
  exit(1)
rescue DBGeni::MigrationNotOutstanding => e
  logger.error "#{e.to_s} does not exist or is not outstanding"
  exit(1)
rescue DBGeni::DBCLINotOnPath => e
  logger.error "The command line interface for the database is not on the path (sqlite3, sqlplus)"
  exit(1)
rescue DBGeni::MilestoneHasNoMigration => e
  logger.error "The milestone does not contain a valid migration"
  exit(1)
rescue DBGeni::PluginDirectoryNotAccessible => e
  logger.error "The plugin directory specified in config is not accessable: #{e.to_s}"
  exit(1)
rescue DBGeni::PluginDoesNotRespondToRun
  logger.error "A pluggin was loaded that does not have a run method: #{e.to_s}"
  exit(1)
end

exit(0)
