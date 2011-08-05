require 'dbinst/blank_slate'
require 'dbinst/config'
require 'dbinst/environment'
require 'dbinst/migration_list'
require 'dbinst/migration'
require 'dbinst/exceptions/exception'

require 'fileutils'

module DBInst

  class Base
    attr_reader :config
   # attr_reader :migrations

    def initialize(config_file)
      initialize_logger
      load_config(config_file)
    end

    def migrations
#      @migrations =
    end

    def outstanding_migrations
    end

    def applied_migrations
    end

    def apply_all_migrations
    end

    def apply_migration(name)
    end

    private

    def initialize_logger
      @logger = nil
    end

    def load_config(config)
      @config = Config.new.load(config)
    end

  end
end
