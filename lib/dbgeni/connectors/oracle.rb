module DBGeni

  module Connector

    class Oracle

      require 'oci8'

      attr_reader :connection
      attr_reader :database

      def self.connect(user, password, database)
        self.new(user, password, database)
      end

      def disconnect
        @connection.logoff
      end

      def execute(sql, *binds)
        begin
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
          else
            # everthing is auto commit right now ...
            @connection.commit
          end
        ensure
          begin
            query.close()
          rescue
          end
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

      def date_placeholder(bind_var)
        "to_date(:#{bind_var}, 'YYYYMMDDHH24MISS')"
      end

      def date_as_string(dtm)
        dtm.strftime '%Y%m%d%H%M%S'
      end

      private

      def initialize(user, password, database)
        @database = database
        begin
          @connection = OCI8.new(user, password, database)
        rescue Exception => e
          raise DBGeni::DBConnectionError, e.to_s
        end
      end

    end
  end
end
