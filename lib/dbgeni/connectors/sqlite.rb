module DBGeni

  module Connector
    class Sqlite

      if RUBY_PLATFORM == 'java'
        require 'rubygems'
        require 'jdbc/sqlite3'
        Java::org.sqlite.JDBC #initialize the driver
      else
        require 'sqlite3'
      end

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
        raise DBGeni::DatabaseNotSpecified unless database
        self.new(database)
      end

      def disconnect
        @connection.close
      end

      def execute(sql, *binds)
#        unless @connection.transaction_active?
#          @connection.transaction
#        end
        if RUBY_PLATFORM == 'java'
          return execute_jdbc(sql, *binds)
        end
        begin
          query = @connection.prepare(sql)
          binds.each_with_index do |b, i|
            query.bind_param(i+1, b)
          end
          results = query.execute!
          # This shouldn't even be needed, as there are never transactions started.
          # by default everthing in sqlite is autocommit
          if @connection.transaction_active?
            @connection.commit
          end
          results
        ensure
          begin
            query.close
          rescue Exception => e
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

      def ping
        ! @connection.closed?
      end

      def commit
        @connection.commit
      end

      def rollback
        @connection.rollback
      end

      def date_placeholder(bind_var)
        "time(:#{bind_var})"
      end

      def date_as_string(dtm)
        dtm.strftime '%Y-%m-%d %H:%M:%S'
      end

      private

      def initialize(database)
        @database   = database
        begin
          if RUBY_PLATFORM == 'java'
            @connection = ::JavaSql::DriverManager.getConnection("jdbc:sqlite:#{database}")
          else
            @connection = SQLite3::Database.new(database)
          end
        rescue Exception => e
          raise DBGeni::DBConnectionError, e.to_s
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
