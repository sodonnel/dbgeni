require 'dbinst/blank_slate'
require 'dbinst/config'
require 'dbinst/environment'

module DBInst

  class Base
    attr_reader :config

    def initialize
    end

    def load_config(config)
      @config = Config.new.load(config)
    end

    def load_config_from_file(filename)
    end
  end
end
