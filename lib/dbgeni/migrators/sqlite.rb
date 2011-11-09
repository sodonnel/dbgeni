module DBGeni
  module Migrator

    class Sqlite

      attr_reader :logfile

      def initialize(config, connection)
        @config = config
        # this is not actually used to run in the sql script
        @connection = connection
        @log_dir    = DBGeni::Logger.instance("#{@config.base_directory}/log").detailed_log_dir
        ensure_executable_exists
      end

      def apply(migration, force=nil)
        filename = File.join(@config.migration_directory, migration.migration_file)
        run_in_sqlite(filename, force)
      end

      def rollback(migration, force=nil)
        filename = File.join(@config.migration_directory, migration.rollback_file)
        run_in_sqlite(filename, force)
      end

      def migration_errors
        ''
      end

      def verify(migration)
        raise DBGeni::NotImplemented
      end

      def compile(code)
        raise DBGeni::NotImplemented
      end

      def remove(code)
        raise DBGeni::NotImplemented
      end

      def code_errors
        raise DBGeni::NotImplemented
      end

      private

      def run_in_sqlite(file, force=nil)
        null_device = '/dev/null'
        if Kernel.is_windows?
          null_device = 'NUL:'
        end

        @logfile = "#{@config.base_directory}/log/#{@log_dir}/#{File.basename(file)}"
        IO.popen("sqlite3 #{@connection.database} > #{@logfile} 2>&1", "w") do |p|
          unless force
            p.puts ".bail on"
          end
          p.puts ".echo on"
          p.puts ".read #{file}"
          p.puts ".quit"
        end
        # On OSX sqlite exits with 0 even when the sql script contains errors.
        # On windows when there are errors it exits with 1.
        #
        # The only way to see if the script contained errors consistently is
        # to grep the logfile for lines starting SQL error near line
        # No point in checking if force is on as the errors don't matter anyway.
        has_errors = false
        unless force
          # For empty migrations, sometimes no logfile?
          if File.exists? @logfile
            File.open(@logfile, 'r').each do |l|
              if l =~ /^SQL error near line/
                has_errors = true
                break
              end
            end
          end
        end
        # When the system call ends, ruby sets $? with the exit status.  A
        # good exit status is 0 (zero) anything else means it went wrong
        # If $? is anything but zero, raise an exception.
        if $? != 0 or has_errors
          # if there were errors in the migration, SQLITE seems to set a non-zero
          # exit status on **windows only**, depite running the migration to completion.
          # So if the exit status is non-zero AND force is NOT true, raise, otherwise don't.
          unless force
            raise DBGeni::MigrationContainsErrors
          end
        end
      end

      def ensure_executable_exists
        unless Kernel.executable_exists?('sqlite3')
          raise DBGeni::DBCLINotOnPath
        end
      end

    end
  end

end
