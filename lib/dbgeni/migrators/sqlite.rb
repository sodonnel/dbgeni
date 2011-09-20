module DBGeni
  module Migrator

    class Sqlite

      def initialize(config, connection)
        @config = config
        # this is not actually used to run in the sql script
        @connection = connection
      end

      def apply(migration, force=nil)
        filename = File.join(@config.migration_directory, migration.migration_file)
        run_in_sqlite(filename, force)
      end

      def rollback(migration, force=nil)
        filename = File.join(@config.migration_directory, migration.rollback_file)
        run_in_sqlite(filename, force)
      end

      def verify(migration)
      end

      private

      def run_in_sqlite(file, force=nil)
        null_device = '/dev/null'
        if Kernel.is_windows?
          null_device = 'NUL:'
        end

        logfile = DBGeni::Migrator.logfile(file)
        IO.popen("sqlite3 #{@connection.database} > #{@config.base_directory}/log/#{logfile} 2>> #{@config.base_directory}/log/#{logfile}", "w") do |p|
          unless force
            p.puts ".bail on"
          end
          p.puts ".echo on"
          p.puts ".output #{@config.base_directory}/log/#{logfile}"
          p.puts ".read #{file}"
          p.puts ".quit"
        end
        # When the system call ends, ruby sets $? with the exit status.  A
        # good exit status is 0 (zero) anything else means it went wrong
        # If $? is anything but zero, raise an exception.
        if $? != 0
          # if there were errors in the migration, SQLITE seems to set a non-zero
          # exit status, depite running the migration to completion. So if the exit
          # is non-zero AND force is NOT true, raise, otherwise don't.
          unless force
            raise DBGeni::MigrationContainsErrors
          end
        end
      end

    end
  end

end
