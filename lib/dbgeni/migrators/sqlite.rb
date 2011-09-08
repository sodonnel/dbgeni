module DBGeni
  module Migrator

    class Sqlite

      def initialize(config, connection)
        @config = config
        # this is not actually used to run in the sql script
        @connection = connection
      end

      def apply(migration)
        filename = File.join(@config.migration_directory, migration.migration_file)
        run_in_sqlite(filename)
      end

      def rollback(migration)
        filename = File.join(@config.migration_directory, migration.rollback_file)
        run_in_sqlite(filename)
      end

      def verify(migration)
      end

      private

      def run_in_sqlite(file)
        null_device = '/dev/null'
        if Kernel.is_windows?
          null_device = 'NUL:'
        end

        logfile = DBGeni::Migrator.logfile(file)
        IO.popen("sqlite3 #{@connection.database} > #{null_device} 2>> #{logfile}", "w") do |p|
          p.puts ".bail on"
          p.puts ".echo on"
          p.puts ".output #{@config.base_directory}/log/#{logfile}"
          p.puts ".read #{file}"
          p.puts ".quit"
        end
        # When the system call ends, ruby sets $? with the exit status.  A
        # good exit status is 0 (zero) anything else means it went wrong
        # If $? is anything but zero, raise an exception.
        if $? != 0
          raise DBGeni::MigrationContainsErrors
        end
      end

    end
  end

end
