module DBGeni

  module Connector

    class Sybase

      unless RUBY_PLATFORM == 'java'
        raise DBGeni::UnsupportedRubyPlatform
      end

      require 'java'
      java_import 'net.sourceforge.jtds.jdbc.Driver'
      java_import 'java.sql.DriverManager'

      attr_reader :connection
      attr_reader :database

      def self.connect(user, password, database, host=nil, port=nil)
        self.new(user, password, database, host, port)
      end

      def disconnect
        @connection.close
      end

      def execute(sql, *binds)
        query = @connection.prepare_statement(sql)
        binds.each_with_index do |b, i|
          if b.is_a?(String)
            query.setString(i+1, b)
          elsif b.is_a?(Fixnum)
            query.setInt(i+1, b)
          end
        end
        results = Array.new
        unless sql =~ /^\s*select/i
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
        query.close
        results
      end

      def ping
        results = self.execute('select 1')
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
        "cast(? as datetime)"
      end

      def date_as_string(dtm)
        dtm.strftime '%Y-%m-%d %H:%M:%S'
      end

      private


      #
      def initialize(user, password, database, host=nil, port=nil)
        @database = database

        sybdriver = Driver.new
        DriverManager.registerDriver sybdriver
        begin
          @connection = DriverManager.get_connection("jdbc:jtds:sybase://#{host}:#{port}/#{database}", user, password)
          @connection.auto_commit = true
        rescue Exception => e
          raise DBGeni::DBConnectionError, e.to_s
        end
      end

    end
  end
end
