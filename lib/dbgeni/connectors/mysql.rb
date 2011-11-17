module DBGeni

  module Connector

    class Mysql
      require 'mysql'

      attr_reader :connection
      attr_reader :database

      def self.connect(user, password, database, host, port)
        self.new(user, password, database, host, port=nil)
      end

      def disconnect
        @connection.close
      end

      def execute(sql, *binds)
        # strange exception handling here. If you issue a select, the fetch works fine.
        # However, something like create table blows up when fetch is called with noMethodError
        # so it is being caught and thrown away ... hackish, but the mysql drive seems to be
        # at fault, is badly documented and seems to be a bit rubbish. Ideall uses DBD::Mysql + DBI.

        results = Array.new
        if sql =~ /^drop\s+(procedure|function|trigger|table)/i
          # cannot prepare these statements, need to just execute
          @connection.query(sql)
          return results
        end

        begin
          query = @connection.prepare(sql)
          query.execute(*binds)

          results = Array.new
          if query.num_rows > 0
            while r = query.fetch()
              results.push r
            end
          end
          # everthing is auto commit right now ...
          @connection.commit
        rescue NoMethodError
        ensure
          begin
            query.close()
          rescue
          end
        end

        results
      end

      def ping
        results = self.execute('select 1 + 1 from dual')
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
        "?" # ":#{bind_var}"
      end

      def date_as_string(dtm)
        dtm.strftime '%Y-%m-%d %H:%M:%S'
      end

      private

      def initialize(user, password, database, host, port=nil)
        @database = database
        begin
          @connection = ::Mysql.connect(host, user, password, database, port)
        rescue Exception => e
          raise DBGeni::DBConnectionError, e.to_s
        end
      end

    end
  end
end

