module DBGeni
  module Migrator

    class Mysql < DBGeni::Migrator::MigratorInterface

      def initialize(config, connection)
        super(config, connection)
      end

      # Defined in super ...
      # def apply(migration, force=nil)
      # end

      # def rollback(migration, force=nil)
      # end

      def migration_errors
        error = ''
        # MYSQL prints the errors at the start of the log file
        begin
          fh = File.open(@logfile, 'r')
          error = fh.readline
          unless error =~ /^ERROR/
            error = ''
          end
        ensure
          fh.close if fh
        end
        error
      end

      def remove(code, force=false)
        begin
          @connection.execute(drop_command(code))
        rescue Exception => e
          unless e.to_s =~ /(procedure|function|trigger).+does not exist/i
            raise DBGeni::CodeRemoveFailed, e.to_s
          end
        end
      end

      def code_errors
        # In mysql the code errors ar just the same as migration errors
        errors = migration_errors
        if errors == ''
          errors = nil
        end
        errors
      end

      private

      def run_in_client(file, force, is_proc=false)
        @logfile = "#{@config.base_directory}/log/#{@log_dir}/#{File.basename(file)}"

        z = @config.env
        response = system("mysql -u#{z.username} -p#{z.password} -h#{z.hostname} -P#{z.port} -D#{z.database} -vvv #{force ? '--force' : ''} <#{file} >#{logfile} 2>&1")
        unless response
          raise DBGeni::MigrationContainsErrors
        end
      end

      def ensure_executable_exists
        unless Kernel.executable_exists?('mysql')
          raise DBGeni::DBCLINotOnPath
        end
      end

      def drop_command(code)
        case code.type
        when DBGeni::Code::TRIGGER
          "drop trigger #{code.name.downcase}"
        when DBGeni::Code::FUNCTION
          "drop function #{code.name.downcase}"
        when DBGeni::Code::PROCEDURE
          "drop procedure #{code.name.downcase}"
        end
      end

    end
  end
end
