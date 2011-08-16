require 'dbinst/blank_slate'
require 'dbinst/config'
require 'dbinst/environment'
require 'dbinst/migration_list'
require 'dbinst/migration'
require 'dbinst/exceptions/exception'
require 'dbinst/initializers/initializer'

require 'fileutils'

module DBInst

  class Base
    attr_reader :config
    attr_reader :connection
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
      rescue DBInst::ConfigAmbigiousEnvironment
        nil
      end
    end

    def migrations
      @migration_list = DBInst::MigrationList.new(@config.migration_directory).migrations
    end

    def outstanding_migrations
    end

    def applied_migrations
    end

    def apply_all_migrations
    end

    def apply_migration(name)
    end

    def connect
      raise DBInst::NoEnvironmentSelected unless selected_environment_name
      return @connection if @connection

      if config.db_type == 'oracle'
        require 'dbinst/connectors/oracle'
        @connection = DBInst::Connector::Oracle.connect(@config.env.username,
                                                        @config.env.password,
                                                        @config.env.database)
      elsif config.db_type == 'sqlite'
        require 'dbinst/connectors/sqlite'
        @connection = DBInst::Connector::Sqlite.connect(nil,
                                                        nil,
                                                        @config.env.database)
      else
        raise DBInst::NoConnectorForDBType, config.db_type
      end
      @connection
    end

    def initialize_database
      self.connect
      DBInst::Initializer.initialize(@connection, @config)
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
