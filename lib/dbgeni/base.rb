require 'forwardable'
require 'dbgeni/logger'
require 'dbgeni/blank_slate'
require 'dbgeni/config'
require 'dbgeni/environment'
require 'dbgeni/file_converter'
#require 'dbgeni/base_migrations'
require 'dbgeni/base_code'
require 'dbgeni/migration_list'
require 'dbgeni/migration'
require 'dbgeni/code_list'
require 'dbgeni/code'
require 'dbgeni/plugin'
require 'dbgeni/exceptions/exception'
require 'dbgeni/initializers/initializer'
require 'dbgeni/migrators/migrator'
require 'dbgeni/migrators/migrator_interface'
require 'dbgeni/connectors/connector'
require 'dbgeni/migration_cli'

require 'fileutils'

module DBGeni

  class Base
    attr_reader :config
   # attr_reader :migrations

    # This pulls in all the migration related methods - listing, applying, rolling back
#    include DBGeni::BaseModules::Migrations
    # This pulls in all the code related methods - listing, applying, removing
    include DBGeni::BaseModules::Code

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
      @migration_cli = MigrationCLI.new(self, @config, @logger)
    end

    def method_missing(meth, *args, &blk)
      if meth =~ /migration/
        @migration_cli.send(meth.intern, *args)
      elsif meth =~ /dml/
        @dml_cli.send(meth.intern, *args)
      else
        super
      end
    end

#    def_delegators(:@migration_cli, :migrations, :outstanding_migrations, :applied_migrations, :applied_and_broken_migrations,
#                   :list_of_migrations, :apply_all_migrations, :apply_next_migration, :apply_until_migration, :apply_list_of_migrations,
#                   :apply_migration, :rollback_all_migrations, :rollback_last_migration, :rollback_until_migration, :rollback_list_of_migrations,
#                   :rollback_migration)


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


    def run_plugin(hook, object, params={})
      pdir = @config.plugin_directory
      if pdir && pdir != ''
        unless @plugin_manager
          @plugin_manager = DBGeni::Plugin.new
          @plugin_manager.load_plugins(pdir)
        end
        @plugin_manager.run_plugins(hook,
                                    {
                                      :logger      => @logger,
                                      :object      => object,
                                      :environment => @config.env,
                                      :connection  => connection
                                    }.merge!(params)
                                    )
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

    def database_initialized?
      DBGeni::Initializer.initialized?(connection, @config)
    end


    def ensure_initialized
      raise DBGeni::DatabaseNotInitialized unless database_initialized?
    end

    private

    def initialize_logger
      @logger = DBGeni::Logger.instance("#{@config.base_directory}/log")
    end

    def load_config(config)
      @config = Config.load_from_file(config)
    end

  end
end
