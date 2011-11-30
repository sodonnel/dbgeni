module DBGeni

  module Connector

    class Sybase

      unless RUBY_PLATFORM == 'java'
        raise DBGeni::UnsupportedRubyPlatform
      end

      require 'java'
      java_import 'net.sourceforge.jtds.jdbc.Driver'
      require 'dbi'
      
      attr_reader :connection
      attr_reader :database

      def self.connect(user, password, database, host=nil, port=nil)
        self.new(user, password, database, host, port)
      end

      def disconnect
        @connection.logoff
      end

      def execute(sql, *binds)
        query = @connection.prepare(sql)
        binds.each_with_index do |b, i|
          query.bind_param(i+1, b)
        end
        results = Array.new
        query.execute()
        while(r = query.fetch()) do
          results.push r
        end
        query.finish
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

      def initialize(user, password, database, host=nil, port=nil)
        @database = database

        begin
          @connection = DBI.connect("dbi:Jdbc:jtds:sybase://#{host}:#{port}/#{database}", user, password,
                                    {'driver' => 'net.sourceforge.jtds.jdbc.Driver'} )
        rescue Exception => e
          raise DBGeni::DBConnectionError, e.to_s
        end
      end

    end
  end
end
