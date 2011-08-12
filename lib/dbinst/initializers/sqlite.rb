module DBInst
  module Initializer
    module Sqlite

      def self.initialize(db_connection, config)
        raise DBInst::DatabaseAlreadyInitialized if self.initialized?(db_connection, config)
        db_connection.execute("create table #{config.db_table}
                               (
                                  migration_name varchar2(4000),
                                  added_dtm      date
                               )")
        db_connection.execute("create unique index #{config.db_table}_uk1 on #{config.db_table} (migration_name)")
      end

      def self.initialized?(db_connection, config)
        # it is initialized if a table called dbinst_migrations or whatever is
        # defined in config exists
        results = db_connection.execute("SELECT name FROM sqlite_master WHERE name = :t", config.db_table.downcase)
        if 0 == results.length
          false
        else
          true
        end
      end

    end
  end
end
