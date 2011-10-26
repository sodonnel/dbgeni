require 'dbgeni/logger'
require 'dbgeni/blank_slate'
require 'dbgeni/config'
require 'dbgeni/environment'
require 'dbgeni/migration_list'
require 'dbgeni/migration'
require 'dbgeni/code_list'
require 'dbgeni/code'
require 'dbgeni/exceptions/exception'
require 'dbgeni/initializers/initializer'
require 'dbgeni/migrators/migrator'
require 'dbgeni/connectors/connector'

require 'fileutils'

module DBGeni

  class Base
    attr_reader :config
   # attr_reader :migrations

    def self.installer_for_environment(config_file, environment_name=nil)
      installer = self.new(config_file)
      # If environment is nil, then it assumes there is only a single environment
      # defined. So pass the nil value to select_environment - if there is more than
      # one environment then select_environment will error out after making a call
      # to get_environment.
      installer.select_environment(environment_name)
      installer
    end

    def initialize(config_file)
      load_config(config_file)
      initialize_logger
    end

    def select_environment(environment_name)
      current_environment = selected_environment_name
      if current_environment != nil && current_environment != environment_name
        # disconnect from database as the connection may well have changed!
        disconnect
      end
      @config.set_env(environment_name)
    end

    def selected_environment_name
      begin
        @config.env.__environment_name
      rescue DBGeni::ConfigAmbiguousEnvironment
        nil
      end
    end

    ######################
    # Listing Migrations #
    ######################

    def migrations
      @migration_list ||= DBGeni::MigrationList.new(@config.migration_directory) unless @migration_list
      @migration_list.migrations
    end

    def outstanding_migrations
      ensure_initialized
      migrations
      @migration_list.outstanding(@config, connection)
    end

    def applied_migrations
      ensure_initialized
      migrations
      @migration_list.applied(@config, connection)
    end

    def applied_and_broken_migrations
      ensure_initialized
      migrations
      @migration_list.applied_and_broken(@config, connection)
    end

    #######################
    # Applying Migrations #
    #######################

    def apply_all_migrations(force=nil)
      ensure_initialized
      migrations = outstanding_migrations
      if migrations.length == 0
        raise DBGeni::NoOutstandingMigrations
      end
      migrations.each do |m|
        apply_migration(m, force)
      end
    end

    def apply_next_migration(force=nil)
      ensure_initialized
      migrations = outstanding_migrations
      if migrations.length == 0
        raise DBGeni::NoOutstandingMigrations
      end
      apply_migration(migrations.first, force)
    end

    def apply_until_migration(migration_name, force=nil)
      ensure_initialized
      milestone = Migration.initialize_from_internal_name(@config.migration_directory, migration_name)
      outstanding = outstanding_migrations
      index = outstanding.index milestone
      unless index
        # milestone migration doesn't exist or is already applied.
        raise MigrationNotOutstanding, milestone.to_s
      end
      0.upto(index) do |i|
        apply_migration(outstanding[i], force)
      end
    end

    def apply_migration(migration, force=nil)
      ensure_initialized
      begin
        migration.apply!(@config, connection, force)
        @logger.info "Applied #{migration.to_s}"
      rescue DBGeni::MigrationApplyFailed
        @logger.error "Failed #{migration.to_s}. Errors in #{migration.logfile}"
        raise DBGeni::MigrationApplyFailed, migration.to_s
      end
    end

    ###########################
    # Rolling back migrations #
    ###########################

    def rollback_all_migrations(force=nil)
      ensure_initialized
      migrations = applied_and_broken_migrations.reverse
      if migrations.length == 0
        raise DBGeni::NoAppliedMigrations
      end
      migrations.each do |m|
        rollback_migration(m, force)
      end
    end

    def rollback_last_migration(force=nil)
      ensure_initialized
      migrations = applied_and_broken_migrations
      if migrations.length == 0
        raise DBGeni::NoAppliedMigrations
      end
      # the most recent one is at the end of the array!!
      rollback_migration(migrations.last, force)
    end

    def rollback_until_migration(migration_name, force=nil)
      ensure_initialized
      milestone = Migration.initialize_from_internal_name(@config.migration_directory, migration_name)
      applied = applied_and_broken_migrations.reverse
      index = applied.index milestone
      unless index
        # milestone migration doesn't exist or is already applied.
        raise DBGeni::MigrationNotApplied, milestone.to_s
      end
      0.upto(index) do |i|
        rollback_migration(applied[i], force)
      end
    end

    def rollback_migration(migration, force=nil)
      ensure_initialized
      begin
        migration.rollback!(@config, connection, force)
        @logger.info  "Rolledback #{migration.to_s}"
      rescue DBGeni::MigrationApplyFailed
        @logger.error "Failed #{migration.to_s}. Errors in #{migration.logfile}"
        raise DBGeni::MigrationApplyFailed, migration.to_s
      end
    end

    ########################
    # Listing Code Modules #
    ########################

    def code
      @code_list ||= DBGeni::CodeList.new(@config.code_dir)
      @code_list.code
    end

    def current_code
      ensure_initialized
      code
      @code_list.current(@config, connection)
    end

    def outstanding_code
      ensure_initialized
      code
      @code_list.outstanding(@config, connection)
    end

    ######################################
    # Applying and removing code modules #
    ######################################

    def apply_all_code
      ensure_initialized
      code_files = code
      if code_files.length == 0
        raise DBGeni::NoOutstandingCode
      end
      code_files.each do |c|
        apply_code(c, true)
      end
    end

    def apply_outstanding_code
      ensure_initialized
      code_files = outstanding_code
      if code_files.length == 0
        raise DBGeni::NoOutstandingCode
      end
      code_files.each do |c|
        apply_code(c, true)
      end
    end

    def apply_code(code_obj, force=nil)
      ensure_initialized
      begin
        code_obj.apply!(@config, connection, force)
        if code_obj.error_messages
          @logger.info "Applied #{code_obj.to_s} (with errors)\n\n#{code_obj.error_messages}\nFull errors in #{code_obj.logfile}\n\n"
        else
          @logger.info "Applied #{code_obj.to_s}"
        end
      rescue DBGeni::CodeApplyFailed => e
        # TODO - the only real way code can get here is if the user had insufficient privs
        # to create the proc, or there was other bad stuff in the proc file.
        # In this case, dbgeni should stop - but also treat the error like a migration error
        # as the error message will be in the logfile in the format standard SQL errors are.
        @logger.error "Failed to apply #{code_obj.to_s}. Errors in #{migration.logfile}"
        raise DBGeni::CodeApplyFailed, e.to_s
      end
    end

    def remove_all_code
      ensure_initialized
      code_files = code
      if code_files.length == 0
        raise DBGeni::NoCodeFilesExist
      end
      code_files.each do |c|
        remove_code(c)
      end
    end

    def remove_code(code_obj, force=nil)
      ensure_initialized
      begin
        code_obj.remove!(@config, connection, force)
        @logger.info "Removed #{code_obj.to_s}"
      rescue DBGeni::CodeRemoveFailed => e
        # TODO - the only real way code can get here is if the user had insufficient privs
        # to create the proc, or there was other bad stuff in the proc file.
        # In this case, dbgeni should stop - but also treat the error like a migration error
        # as the error message will be in the logfile in the format standard SQL errors are.

        @logger.error "Failed to remove #{code_obj.to_s}. Errors in #{migration.logfile}"
        raise DBGeni::CodeRemoveFailed
      end
    end

    ###########################
    # Various utility methods #
    ###########################

    def connect
      raise DBGeni::NoEnvironmentSelected unless selected_environment_name
      return @connection if @connection

      @connection = DBGeni::Connector.initialize(@config)
    end

    def disconnect
      if @connection
        @connection.disconnect
      end
      @connection = nil
    end

    def connection
      @connection ||= connect
    end

    def initialize_database
      DBGeni::Initializer.initialize(connection, @config)
    end

    private

    def ensure_initialized
      raise DBGeni::DatabaseNotInitialized unless DBGeni::Initializer.initialized?(connection, @config)
    end

    def initialize_logger
      @logger = DBGeni::Logger.instance("#{@config.base_directory}/log")
    end

    def load_config(config)
      @config = Config.load_from_file(config)
    end

  end
end
