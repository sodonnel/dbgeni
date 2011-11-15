module DBGeni
  module Migrator

    class MigratorInterface

      attr_reader :logfile

      def apply(migration, force=nil)
        filename = File.join(@config.migration_directory, migration.migration_file)
        run_in_client(filename, force)
      end

      def rollback(migration, force=nil)
        filename = File.join(@config.migration_directory, migration.rollback_file)
        run_in_client(filename, force)
      end

      def migration_errors
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

      def run_in_client(file, force, is_proc=false)
      end

      def initialize(config, connection)
        @config = config
        # this is not actually used to run in the sql script
        @connection = connection
        @logfile    = nil
        @log_dir    = DBGeni::Logger.instance("#{@config.base_directory}/log").detailed_log_dir
        ensure_executable_exists
      end
    end

  end
end
