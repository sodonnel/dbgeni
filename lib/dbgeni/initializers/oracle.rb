module DBGeni
  module Initializer
    module Oracle

      def self.initialize(db_connection, config)
        raise DBGeni::DatabaseAlreadyInitialized if self.initialized?(db_connection, config)
        db_connection.execute("create table #{config.db_table}
                               (
                                  sequence_or_hash varchar2(100) not null,
                                  migration_name   varchar2(4000) not null,
                                  migration_type   varchar2(20)   not null,
                                  migration_state  varchar2(20)   not null,
                                  start_dtm        date,
                                  completed_dtm    date
                               )")
        db_connection.execute("create unique index #{config.db_table}_uk1 on #{config.db_table} (sequence_or_hash, migration_name, migration_type)")
        db_connection.execute("create index #{config.db_table}_idx2 on #{config.db_table} (migration_name)")
      end

      def self.initialized?(db_connection, config)
        # it is initialized if a table called dbgeni_migrations or whatever is
        # defined in config exists
        results = db_connection.execute("select table_name from all_tables where table_name = :t and owner = :o",
                                        config.db_table.upcase,
                                        config.env.install_schema ? config.env.install_schema.upcase : config.env.username.upcase)
        if 0 == results.length
          false
        else
          true
        end
      end

    end
  end
end



