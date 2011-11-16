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

     # def verify(migration)
     # end

#      def compile(code)
#        run_in_client(File.join(@config.code_directory, code.filename), false, true)
#      end

#      def remove(code)
#        begin
#          @connection.execute(drop_command(code))
#        rescue Exception => e
#          unless e.to_s =~ /(object|trigger) .+ does not exist/
#            raise DBGeni::CodeRemoveFailed, e.to_s
#          end
#        end
#      end

      # def code_errors
      #   # The error part of the file file either looks like:

      #   # SQL> show err
      #   # No errors.
      #   # SQL> spool off

      #   # or

      #   # SQL> show err
      #   # Errors for PACKAGE BODY PKG1:

      #   # LINE/COL ERROR
      #   # -------- -----------------------------------------------------------------
      #   # 5/1      PLS-00103: Encountered the symbol "END" when expecting one of the
      #   # following:
      #   # Error messages here
      #   # SQL> spool off

      #   # In the first case, return nil, but in the second case get everything after show err

      #   error_msg = ''
      #   start_search = false
      #   File.open(@logfile, 'r').each_line do |l|
      #     if !start_search && l =~ /^SQL> show err/
      #       start_search = true
      #       next
      #     end
      #     if start_search
      #       if l =~ /^No errors\./
      #         error_msg = nil
      #         break
      #       elsif l =~ /^SQL> spool off/
      #         break
      #       else
      #         error_msg << l
      #       end
      #     end
      #   end
      #   error_msg
      # end

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
        when DBGeni::Code::PACKAGE_SPEC
          "drop package #{code.name}"
        when DBGeni::Code::PACKAGE_BODY
          "drop package body #{code.name}"
        when DBGeni::Code::TRIGGER
          "drop trigger #{code.name}"
        when DBGeni::Code::FUNCTION
          "drop function #{code.name}"
        when DBGeni::Code::PROCEDURE
          "drop procedure #{code.name}"
        end
      end

    end
  end
end
