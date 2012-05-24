module DBGeni

  module Connector

    class Mysql
      if RUBY_PLATFORM == 'java'
        require 'java'
        java_import 'com.mysql.jdbc.Driver'
        java_import 'java.sql.DriverManager'
      else
        require 'mysql'
      end

      attr_reader :connection
      attr_reader :database

      def self.connect(user, password, database, host, port)
        self.new(user, password, database, host, port=nil)
      end

      def disconnect
        @connection.close
      end

      def execute(sql, *binds)
        if RUBY_PLATFORM == 'java'
          execute_jdbc(sql, *binds)
        else
          execute_native(sql, *binds)
        end
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

      def initialize(user, password, database, host, port=3306)
        @database = database
        begin
          if RUBY_PLATFORM == 'java'
            @connection = DriverManager.get_connection("jdbc:mysql://#{host}:#{port||3306}/#{database}", user, password)
          else
            @connection = ::Mysql.connect(host, user, password, database, port)
          end
        rescue Exception => e
          raise DBGeni::DBConnectionError, e.to_s
        end
      end

      def execute_native(sql, *binds)
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

      def execute_jdbc(sql, *binds)
        begin
          query = @connection.prepare_statement(sql)
          binds.each_with_index do |b, i|
            if b.is_a?(String)
              query.setString(i+1, b)
            elsif b.is_a?(Fixnum)
              query.setInt(i+1, b)
            end
          end
          results = Array.new
          unless sql =~ /^\s*(select|show)/i
            query.execute()
          else
            rset = query.execute_query()
            cols = rset.get_meta_data.get_column_count
            while(r = rset.next) do
              a = Array.new
              1.upto(cols) do |i|
                a.push rset.get_object(i)
              end
              results.push a
            end
          end
          results
        ensure
          begin
            query.close
          rescue Exception => e
          end
        end
      end

    end
  end
end

