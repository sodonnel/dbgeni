module DBGeni
  module Migrator

    class Oracle

      attr_reader :logfile

      def initialize(config, connection)
        @config = config
        # this is not actually used to run in the sql script
        @connection = connection
        @logfile    = nil
        ensure_executable_exists
      end

      def apply(migration, force=nil)
        filename = File.join(@config.migration_directory, migration.migration_file)
        run_in_sqlplus(filename, force)
      end

      def rollback(migration, force=nil)
        filename = File.join(@config.migration_directory, migration.rollback_file)
        run_in_sqlplus(filename, force)
      end

      def migration_errors
        nil
      end

      def verify(migration)
        raise DBGeni::NotImplemented
      end

      def compile(code)
        run_in_sqlplus(File.join(@config.code_directory, code.filename), false, true)
      end

      def remove(code)
        begin
          @connection.execute(drop_command(code))
        rescue Exception => e
          unless e.to_s =~ /(object|trigger) .+ does not exist/
            raise DBGeni::CodeRemoveFailed, e.to_s
          end
        end
      end

      def code_errors
        # The error part of the file file either looks like:

        # SQL> show err
        # No errors.
        # SQL> spool off

        # or

        # SQL> show err
        # Errors for PACKAGE BODY PKG1:

        # LINE/COL ERROR
        # -------- -----------------------------------------------------------------
        # 5/1      PLS-00103: Encountered the symbol "END" when expecting one of the
        # following:
        # Error messages here
        # SQL> spool off

        # In the first case, return nil, but in the second case get everything after show err

        error_msg = ''
        start_search = false
        File.open(@logfile, 'r').each_line do |l|
          if !start_search && l =~ /^SQL> show err/
            start_search = true
            next
          end
          if start_search
            if l =~ /^No errors\./
              error_msg = nil
              break
            elsif l =~ /^SQL> spool off/
              break
            else
              error_msg << l
            end
          end
        end
        error_msg
      end

      private

      def run_in_sqlplus(file, force, is_proc=false)
        null_device = '/dev/null'
        if Kernel.is_windows?
          null_device = 'NUL:'
        end
        @logfile = "#{@config.base_directory}/log/#{DBGeni::Migrator.logfile(file)}"

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
          p.puts "spool #{@logfile}"
          p.puts "START #{file}"
          if is_proc
            p.puts "/"
            p.puts "show err"
          end
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

      def ensure_executable_exists
        unless Kernel.executable_exists?('sqlite3')
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
