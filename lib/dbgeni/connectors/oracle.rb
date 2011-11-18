module DBGeni

  module Connector

    class Oracle

      if RUBY_PLATFORM == 'java'
        require 'java'
        java_import 'oracle.jdbc.OracleDriver'
        java_import 'java.sql.DriverManager'
      else
        require 'oci8'
      end

      attr_reader :connection
      attr_reader :database

      def self.connect(user, password, database, host=nil, port=nil)
        self.new(user, password, database)
      end

      def disconnect
        @connection.logoff
      end

      def execute(sql, *binds)
        if RUBY_PLATFORM == 'java'
          return execute_jdbc(sql, *binds)
        end

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

      def initialize(user, password, database, host=nil, port=nil)
        @database = database

        if RUBY_PLATFORM == 'java'
          oradriver = OracleDriver.new
          DriverManager.registerDriver oradriver
          begin
            @connection = DriverManager.get_connection("jdbc:oracle:thin:@10.152.97.152/#{database}.world", user, password)
            @connection.auto_commit = true
          rescue Exception => e
            raise DBGeni::DBConnectionError, e.to_s
          end
        else
          begin
            @connection = OCI8.new(user, password, database)
          rescue Exception => e
            raise DBGeni::DBConnectionError, e.to_s
          end
        end
      end

      def execute_jdbc(sql, *binds)
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


    end
  end
end
