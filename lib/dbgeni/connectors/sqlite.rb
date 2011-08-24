module DBGeni

  module Connector

    class Sqlite

      require 'sqlite3'

      attr_reader :connection
      attr_reader :database

      def self.db_file_path(base, file)
        # starts with a ., eg ./filename, or does not
        # contain any forward or backslashes, eg db.sqlite3
        if file =~ /^\./ || file !~ /\/|\\/
          # it is a relative path, so join to base directory
          File.join(base, file)
        else
          file
        end
      end

      def self.connect(user, password, database)
        self.new(database)
      end

      def disconnect
        @connection.close
      end

      def execute(sql, *binds)
#        unless @connection.transaction_active?
#          @connection.transaction
#        end
        query = @connection.prepare(sql)
        binds.each_with_index do |b, i|
          query.bind_param(i+1, b)
        end
        results = query.execute!
        query.close
        # This shouldn't even be needed, as there are never transactions started.
        # by default everthing in sqlite is autocommit
        if @connection.transaction_active?
          @connection.commit
        end
        results
      end

      def ping
        ! @connection.closed?
      end

      def commit
        @connection.commit
      end

      def rollback
        @connection.rollback
      end

      private

      def initialize(database)
        @connection = SQLite3::Database.new(database)
        @database   = database
      end

    end

  end
end
