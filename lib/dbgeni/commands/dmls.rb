if %w(-h --help).include? ARGV[0]
  puts <<-EOF
Usage: dbgeni dmls command <--environment-name env_name> <--config-file path/to/config> <--force>

If config-file is not specified, then a file called .dbgeni in the current directory will be
used if it exists, otherwise an error will occurr

If there is more than one environment defined in the config file, then environment-name must
be specified.

If --force is specified, the migration will run to completion and be marked as Completed even
if errors occur.

-e can be used as an abbreviation for --environment-name
-c can be used as an abbreviation for --config-file
-f can be used as an abbreviation for --force


Avaliable commands are:

Readonly
--------

list        Prints out all available dml migrations
            dbgeni dmls list --config-file /home/myapp/.dbgeni

applied     Prints all dml migrations which have been applied to an environment
            dbgeni dmls applied --environment-name test --config-file /home/myapp/.dbgeni

outstanding Prints all dml migrations which have not been applied to an environment
            dbgeni dmls outstanding --environment-name test --config-file /home/myapp/.dbgeni


Destructive
-----------

apply       Apply dml migrations to the given environment. Can specify:

              all       Apply all outstanding dml migrations
              next      Apply only the next dml migration and stop
              until     Apply upto and including the specified dml migration
              specific dml migrations to apply
              milestone Apply upto a specified milestone

            dbgeni dmls apply all  --environment-name test --config-file /home/myapp/.dbgeni <--force>
            dbgeni dmls apply next --environment-name test --config-file /home/myapp/.dbgeni <--force>
            dbgeni dmls apply until YYYYMMDDHHMM::Name1 --environment-name test --config-file /home/myapp/.dbgeni <--force>
            dbgeni dmls apply YYYYMMDDHHMM::Name1 YYYYMMDDHHMM::Name2 YYYYMMDDHHMM::Name3 --environment-name test --config-file /home/myapp/.dbgeni <--force>
            dbgeni dmls apply milestone release_1.0 --environment-name test --config-file /home/myapp/.dbgeni <--force>

rollback    Run the rollback script for a given dml migration. Can specify:

            all       Rollback everything that has even been applied
            last      Rollback the last dml migration applied
            until     Rollback from the last applied dml migration until and including the specified migration
            specific migrations to rollback

            dbgeni dmls rollback all  --environment-name test --config-file /home/myapp/.dbgeni <--force>
            dbgeni dmls rollback last --environment-name test --config-file /home/myapp/.dbgeni <--force>
            dbgeni dmls rollback until YYYYMMDDHHMM::Name1 --environment-name test --config-file /home/myapp/.dbgeni <--force>
            dbgeni dmls rollback YYYYMMDDHHMM::Name1 YYYYMMDDHHMM::Name2 YYYYMMDDHHMM::Name3 --environment-name test --config-file /home/myapp/.dbgeni <--force>
            dbgeni dmls rollback milestone release_1.0 --environment-name test --config-file /home/myapp/.dbgeni <--force>

EOF
  exit
end

command = ARGV.shift

installer = nil
installer = DBGeni::Base.installer_for_environment($config_file, $environment_name)

logger    = DBGeni::Logger.instance

begin
  case command
  when 'list'
    migrations = installer.dmls
    if migrations.length == 0
      logger.info "There are no dml migrations in #{installer.config.dml_directory}"
    end
    migrations.each do |m|
      puts m.to_s
    end
  when 'applied'
    applied = installer.applied_dmls
    if applied.length == 0
      logger.info "There are no applied dml migrations in #{installer.config.dml_directory}"
    end
    applied.each do |m|
      puts m.to_s
    end
  when 'outstanding'
    outstanding = installer.outstanding_dmls
    if outstanding.length == 0
      logger.info "There are no outstanding dml migrations in #{installer.config.dml_directory}"
    end
    outstanding.each do |m|
      puts m.to_s
    end

  when 'apply'
    sub_command = ARGV.shift
    case sub_command
    when 'all'
      installer.apply_all_dmls($force)
    when 'next'
      installer.apply_next_dml($force)
    when 'until', 'milestone'
      migration_name = nil
      if sub_command == 'milestone'
        unless ARGV[0]
          logger.error "A milestone must be specified"
          exit(1)
        end
        unless File.exists? File.join(installer.config.dml_directory, "#{ARGV[0]}.milestone")
          logger.error "The milestone #{ARGV[0]} does not exist"
          exit(1)
        end
        migration_name = DBGeni::Migration.internal_name_from_filename(
                            DBGeni::Migration.get_milestone_migration(
                              installer.config.dml_directory, "#{ARGV[0]}.milestone"))
      else
        # a migration name needs to be the next parameter
        migration_name = ARGV[0]
      end

      unless migration_name
        logger.error "A dml migration name must be specified"
        exit(1)
      end
      # and the migration needs to be in the correct format
      unless migration_name =~ /^(\d{12})::/
        logger.error "#{migration_name} is not a valid dml migration name"
        exit(1)
      end
      installer.apply_until_dml(migration_name, $force)
    when /^(\d{12})::/
      # The param list are specific migration files, but in the internal format. One is
      # stored in sub_command and the rest are in ARGV. Grab all params that match the
      # parameter name format
      files = ARGV.select{ |f| f =~ /^(\d{12})::/ }
      files.unshift sub_command
      installer.apply_list_of_dmls(files, $force)
    else
      logger.error "#{sub_command} is not a valid command"
    end

  when 'rollback'
    sub_command = ARGV.shift
    case sub_command
    when 'all'
      installer.rollback_all_dmls($force)
    when 'last'
      installer.rollback_last_dml($force)
    when 'until', 'milestone'
      migration_name = nil
      if sub_command == 'milestone'
        unless ARGV[0]
          logger.error "You must specify a milestone"
          exit(1)
        end
        unless File.exists? File.join(installer.config.dml_directory, "#{ARGV[0]}.milestone")
          logger.error "The milestone #{ARGV[0]} does not exist"
          exit(1)
        end
        migration_name = DBGeni::Migration.internal_name_from_filename(
                            DBGeni::Migration.get_milestone_migration(
                              installer.config.dml_directory, "#{ARGV[0]}.milestone"))
      else
        # a migration name needs to be the next parameter
        migration_name = ARGV[0]
      end

      unless migration_name
        logger.error "A dml migration name must be specified"
        exit(1)
      end
      # and the migration needs to be in the correct format
      unless migration_name =~ /^(\d{12})::/
        logger.error "#{migration_name} is not a valid dml migration name"
        exit(1)
      end
      installer.rollback_until_dml(migration_name, $force)
    when /^(\d{12})::/
      # The param list are specific migration files, but in the internal format. One is
      # stored in sub_command and the rest are in ARGV. Grab all params that match the
      # parameter name format
      files = ARGV.select{ |f| f =~ /^(\d{12})::/ }
      files.unshift sub_command
      installer.rollback_list_of_dmls(files, $force)
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
  logger.info "There are no outstanding dml migrations to apply"
  exit(0)
rescue DBGeni::MigrationApplyFailed => e
  logger.error "There was a problem #{command == 'rollback' ? 'rolling back' : 'applying' } #{e.to_s}"
  exit(1)
rescue DBGeni::MigrationAlreadyApplied => e
  logger.error "The dml migration is already applied #{e.to_s}"
  exit(1)
rescue DBGeni::MigrationFileNotExist => e
  logger.error "The dml migration file #{e.to_s} does not exist"
  exit(1)
rescue DBGeni:: DatabaseNotInitialized => e
  logger.error "The database needs to be initialized with the command dbgeni initialize"
  exit(1)
rescue DBGeni::NoAppliedMigrations => e
  logger.error "There are no applied dml migrations to rollback"
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
  logger.error "The milestone does not contain a valid dml migration"
  exit(1)
rescue DBGeni::PluginDirectoryNotAccessible => e
  logger.error "The plugin directory specified in config is not accessable: #{e.to_s}"
  exit(1)
rescue DBGeni::PluginDoesNotRespondToRun
  logger.error "A pluggin was loaded that does not have a run method: #{e.to_s}"
  exit(1)
end

exit(0)
