require 'dbgeni/logger'
require 'dbgeni/blank_slate'
require 'dbgeni/config'
require 'dbgeni/environment'
require 'dbgeni/migration_list'
require 'dbgeni/migration'
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

    def apply_all_migrations
      ensure_initialized
      migrations = outstanding_migrations
      if migrations.length == 0
        raise DBGeni::NoOutstandingMigrations
      end
      migrations.each do |m|
        apply_migration(m)
      end
    end

    def apply_next_migration
      ensure_initialized
      migrations = outstanding_migrations
      if migrations.length == 0
        raise DBGeni::NoOutstandingMigrations
      end
      apply_migration(migrations.first)
    end

    def apply_migration(migration)
      ensure_initialized
      begin
        migration.apply!(@config, connection)
        @logger.info "Applied #{migration.to_s}"
      rescue DBGeni::MigrationApplyFailed
        @logger.error "Failed #{migration.to_s}"
        raise DBGeni::MigrationApplyFailed, migration.to_s
      end
    end

    def rollback_all_migrations
      ensure_initialized
      migrations = applied_migrations.reverse
      if migrations.length == 0
        raise DBGeni::NoAppliedMigrations
      end
      migrations.each do |m|
        rollback_migration(m)
      end
    end

    def rollback_last_migration
      ensure_initialized
      migrations = applied_migrations
      if migrations.length == 0
        raise DBGeni::NoAppliedMigrations
      end
      # the most recent one is at the end of the array!!
      rollback_migration(migrations.last)
    end

    def rollback_migration(migration)
      ensure_initialized
      begin
        migration.rollback!(@config, connect)
        @logger.info  "Rolledback #{migration.to_s}"
      rescue DBGeni::MigrationApplyFailed
        @logger.error "Failed #{migration.to_s}"
        raise DBGeni::MigrationApplyFailed, migration.to_s
      end
    end

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
