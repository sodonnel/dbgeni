module DBInst

  module Connector

    class Sqlite

      require 'sqlite3'

      attr_reader :connection

      def self.connect(user, password, database)
        self.new(database)
      end

      def disconnect
        @connection.close
      end

      def execute(sql, *binds)
        query = @connection.prepare(sql)
        binds.each_with_index do |b, i|
          query.bind_param(i+1, b)
        end
        results = query.execute!
        query.close
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
      end

    end

  end
end
