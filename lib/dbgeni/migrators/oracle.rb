module DBGeni
  module Migrator

    class Oracle

      def initialize(config, connection)
        @config = config
        # this is not actually used to run in the sql script
        @connection = connection
      end

      def apply(migration, force=nil)
        filename = File.join(@config.migration_directory, migration.migration_file)
        run_in_sqlplus(filename, force)
      end

      def rollback(migration, force=nil)
        filename = File.join(@config.migration_directory, migration.rollback_file)
        run_in_sqlplus(filename, force)
      end

      def verify(migration)
      end

      private

      def run_in_sqlplus(file, force)
        null_device = '/dev/null'
        if Kernel.is_windows?
          null_device = 'NUL:'
        end

#        sql_parameters = parameters
#        unless parameters
#          sql_parameters = checkSQLPlusParameters(file)
#        end

        IO.popen("sqlplus -L #{@config.env.username}/#{@config.env.password}@#{@config.env.database} > #{null_device}", "w") do |p|
          p.puts "set TERM on"
          p.puts "set ECHO on"
          #            if sql_parameters == ''
          p.puts "set define off"
          #            end
          unless force
            p.puts "whenever sqlerror exit sql.sqlcode"
          end
          #            p.puts "START #{File.basename(file)} #{sql_parameters}"
          p.puts "spool #{@config.base_directory}/log/#{DBGeni::Migrator.logfile(file)}"
          p.puts "START #{file}"
          p.puts "spool off"
          p.puts "exit"
        end
          # When the pipe block ends, ruby sets $? with the exit status.  A
          # good exit status is 0 (zero) anything else means it went wrong
          # If $? is anything but zero, raise an exception.
        if $? != 0
          raise DBGeni::MigrationContainsErrors
        end
      end

    end
  end
end
