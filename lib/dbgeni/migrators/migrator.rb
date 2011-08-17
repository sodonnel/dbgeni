module DBGeni

  module Migrator

    def self.initialize(config, connection)
      required_class = setup(config.db_type)
      begin
        required_method = required_class.method("new")
      rescue NameError
        raise DBGeni::InvalidMigratorForDBType, config.db_type
      end
      required_method.call(config, connection)
    end

    private

    def self.setup(db_type)
      begin
        require "dbgeni/migrators/#{db_type}"
      rescue
        raise DBGeni::NoMigratorForDBType, db_type
      end

      required_class = nil
      if Migrator.const_defined?(db_type.capitalize)
        required_class = Migrator.const_get(db_type.capitalize)
      else
        raise DBGeni::NoMigratorForDBType, db_type
      end
      required_class
    end

  end

end
