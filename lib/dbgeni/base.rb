require 'dbgeni/blank_slate'
require 'dbgeni/config'
require 'dbgeni/environment'
require 'dbgeni/migration_list'
require 'dbgeni/migration'
require 'dbgeni/exceptions/exception'
require 'dbgeni/initializers/initializer'
require 'dbgeni/migrators/migrator'

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
      initialize_logger
      load_config(config_file)
    end

    def select_environment(environment_name)
      @config.set_env(environment_name)
    end

    def selected_environment_name
      begin
        @config.env.__environment_name
      rescue DBGeni::ConfigAmbigiousEnvironment
        nil
      end
    end

    def migrations
      @migration_list ||= DBGeni::MigrationList.new(@config.migration_directory) unless @migration_list
      @migration_list.migrations
    end

    def outstanding_migrations
      migrations.reject {|m| m.applied?(@config, connection) }
    end

    def applied_migrations
      migrations.select {|m| m.applied?(@config, connection) }
    end

    def apply_all_migrations
      migrations = outstanding_migrations
      if migrations.length == 0
        raise DBGeni::NoOutstandingMigrations
      end
      migrations.each do |m|
        begin
          m.apply!(@config, connection)
        rescue Exception => e
          puts "Migration #{m.to_s} failed #{e.to_s}"
          raise
        end
      end
    end


    def apply_next_migration
      migrations = outstanding_migrations
      if migrations.length == 0
        raise DBGeni::NoOutstandingMigrations
      end
      begin
        migrations.first.apply!(@config, connection)
      rescue Exception => e
        puts "Migration #{m.to_s} failed #{e.to_s}"
        raise
      end
    end

    def apply_migration(migration)
    end

    def connect
      raise DBGeni::NoEnvironmentSelected unless selected_environment_name
      return @connection if @connection

      if config.db_type == 'oracle'
        require 'dbgeni/connectors/oracle'
        @connection = DBGeni::Connector::Oracle.connect(@config.env.username,
                                                        @config.env.password,
                                                        @config.env.database)
      elsif config.db_type == 'sqlite'
        require 'dbgeni/connectors/sqlite'
        @connection = DBGeni::Connector::Sqlite.connect(nil,
                                                        nil,
                                                        DBGeni::Connector::Sqlite.db_file_path(@config.base_directory, @config.env.database))
      else
        raise DBGeni::NoConnectorForDBType, config.db_type
      end
      @connection
    end

    def connection
      @connection ||= connect
    end

    def initialize_database
      DBGeni::Initializer.initialize(connection, @config)
    end

    private

    def initialize_logger
      @logger = nil
    end

    def load_config(config)
      @config = Config.load_from_file(config)
    end

  end
end
