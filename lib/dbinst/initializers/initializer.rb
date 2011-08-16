module DBGeni
  module Initializer

    def self.initialize(db_connection, config)
      required_module = setup(config.db_type)
      begin
        required_method = required_module.method("initialize")
      rescue NameError
        raise DBGeni::InvalidInitializerForDBType, config.db_type
      end
      required_method.call(db_connection, config)
    end

    def self.initialized?(db_connection, config)
      required_module = setup(config.db_type)
      begin
        required_method = required_module.method("initialized?")
      rescue NameError
        raise DBGeni::InvalidInitializerForDBType, config.db_type
      end
      required_method.call(db_connection, config)
    end

    private

    def self.setup(db_type)
      begin
        require "dbgeni/initializers/#{db_type}"
      rescue
        raise DBGeni::NoInitializerForDBType, db_type
      end

      required_module = nil
      if Initializer.const_defined?(db_type.capitalize)
        required_module = Initializer.const_get(db_type.capitalize)
      else
        raise raise DBGeni::NoInitializerForDBType, db_type
      end
      required_module
    end

  end
end

