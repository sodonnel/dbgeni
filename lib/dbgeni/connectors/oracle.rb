module DBGeni

  module Connector

    class Oracle

      require 'oci8'

      attr_reader :connection

      def self.connect(user, password, database)
        self.new(user, password, database)
      end

      def disconnect
        @connection.logoff
      end

      def execute(sql, *binds)
        query = @connection.parse(sql)
        binds.each_with_index do |b, i|
          query.bind_param(i+1, b)
        end
        query.exec()
        results = nil
        if query.type == OCI8::STMT_SELECT
          results = Array.new
          while r = query.fetch()
            results.push r
          end
          query.close
        else
          # everthing is auto commit right now ...
          @connection.commit
        end
        results
      end

      def ping
        results = self.execute('select dummy from dual')
        if results.length == 1
          true
        else
          false
        end
      end

      def commit
        @connection.commit
      end

      def rollback
        @connection.rollback
      end


      private

      def initialize(user, password, database)
        @connection = OCI8.new(user, password, database)
      end

    end

  end
end
