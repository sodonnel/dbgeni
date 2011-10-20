module DBGeni
  module Initializer
    module Sqlite

      def self.initialize(db_connection, config)
        raise DBGeni::DatabaseAlreadyInitialized if self.initialized?(db_connection, config)
        db_connection.execute("create table #{config.db_table}
                               (
                                  sequence_or_hash varchar2(1000) not null,
                                  migration_name   varchar2(4000) not null,
                                  migration_type   varchar2(20)   not null,
                                  migration_state  varchar2(20)   not null,
                                  start_dtm        date,
                                  completed_dtm    date
                               )")
        db_connection.execute("create unique index #{config.db_table}_uk1 on #{config.db_table} (sequence_or_hash, migration_name)")
        db_connection.execute("create index #{config.db_table}_idx2 on #{config.db_table} (migration_name)")
      end

      def self.initialized?(db_connection, config)
        # it is initialized if a table called dbgeni_migrations or whatever is
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
