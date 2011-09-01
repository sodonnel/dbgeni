module DBGeni

  module Connector

    def self.initialize(config)
      required_class = setup(config.db_type)
      begin
        required_method = required_class.method("connect")
      rescue NameError
        raise DBGeni::InvalidConnectorForDBType, config.db_type
      end
      required_method.call(config.env.username, config.env.password, config.env.database)
    end

    private

    def self.setup(db_type)
      begin
        require "dbgeni/connectors/#{db_type}"
      rescue
        raise DBGeni::NoConnectorForDBType, db_type
      end

      required_class = nil
      if Connector.const_defined?(db_type.capitalize)
        required_class = Connector.const_get(db_type.capitalize)
      else
        raise DBGeni::NoConnectorForDBType, db_type
      end
      required_class
    end

  end

end

