module DBGeni
  module Initializer
    module Oracle

      def self.initialize(db_connection, config)
        raise DBGeni::DatabaseAlreadyInitialized if self.initialized?(db_connection, config)
        db_connection.execute("create table #{config.db_table}
                               (
                                  migration_name varchar2(4000),
                                  added_dtm      date
                               )")
        db_connection.execute("create unique index #{config.db_table}_uk1 on #{config.db_table} (migration_name)")
      end

      def self.initialized?(db_connection, config)
        # it is initialized if a table called dbgeni_migrations or whatever is
        # defined in config exists
        results = db_connection.execute("select table_name from user_tables where table_name = :t", config.db_table.upcase)
        if 0 == results.length
          false
        else
          true
        end
      end

    end
  end
end



