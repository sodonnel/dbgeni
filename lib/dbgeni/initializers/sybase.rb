module DBGeni
  module Initializer
    module Sybase

      def self.initialize(db_connection, config)
        raise DBGeni::DatabaseAlreadyInitialized if self.initialized?(db_connection, config)
        db_connection.execute("create table #{config.db_table}
                               (
                                  sequence_or_hash varchar(100) not null,
                                  migration_name   varchar(1100) not null,
                                  migration_type   varchar(20)   not null,
                                  migration_state  varchar(20)   not null,
                                  start_dtm        datetime      null,
                                  completed_dtm    datetime      null
                               )")
        db_connection.execute("create unique index #{config.db_table}_uk1 on #{config.db_table} (sequence_or_hash, migration_name)")
        db_connection.execute("create index #{config.db_table}_idx2 on #{config.db_table} (migration_name)")
      end

      def self.initialized?(db_connection, config)
        # it is initialized if a table called dbgeni_migrations or whatever is
        # defined in config exists
        results = db_connection.execute("select name from sysobjects where name = \?", config.db_table.downcase)
        if 0 == results.length
          false
        else
          true
        end
      end

    end
  end
end

