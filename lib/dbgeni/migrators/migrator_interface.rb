module DBGeni
  module Migrator

    class MigratorInterface

      attr_reader :logfile

      def apply(migration, force=nil)
        run_in_client(migration.runnable_migration, force)
      end

      def rollback(migration, force=nil)
        run_in_client(migration.runnable_rollback, force)
      end

      def migration_errors
      end

      def verify(migration)
        raise DBGeni::NotImplemented
      end

      def compile(code, force=false)
        run_in_client(code.runnable_code, force, true)
      end

      def remove(code, force=false)
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
