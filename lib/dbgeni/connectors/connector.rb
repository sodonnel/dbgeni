module DBGeni

  module Connector

    def self.initialize(config)
      required_class = setup(config.db_type)
      conn = nil
      begin
        required_method = required_class.method("connect")
      rescue NameError
        raise DBGeni::InvalidConnectorForDBType, config.db_type
      end
      if config.db_type == 'sqlite' or (config.db_type == 'oracle' and RUBY_PLATFORM != 'java')
        # don't need a host or port here, so make this a seperate call block
        conn = required_method.call(config.env.username,
                               # SQLITE doesn't need a password, so prevent asking for it
                               # or it may be promoted for
                               config.db_type == 'sqlite' ? '' : config.env.password,
                               config.env.database)
      else
        conn = required_method.call(config.env.username,
                                    config.env.password,
                                    config.env.database,
                                    config.env.hostname,
                                    config.env.port)
      end
      if config.db_type == 'oracle'
        if config.env.install_schema
          if config.env.username != config.env.install_schema
            conn.execute("alter session set current_schema=#{config.env.install_schema}")
          end
        end
      end
      conn
    end

    private

    def self.setup(db_type)
      begin
        require "dbgeni/connectors/#{db_type}"
      rescue Exception => e
        puts "Error requiring connector: #{e.to_s}"
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

