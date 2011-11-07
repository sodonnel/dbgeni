module DBGeni
  module Migrator

    class Oracle

      attr_reader :logfile

      def initialize(config, connection)
        @config = config
        # this is not actually used to run in the sql script
        @connection = connection
        @logfile    = nil
        @log_dir    = DBGeni::Logger.instance("#{@config.base_directory}/log").detailed_log_dir
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
        has_errors = false
        buffer = []

        File.open(@logfile, 'r').each_line do |l|
          buffer.push l
          if buffer.length > 10
            buffer.shift
          end
          if !has_errors && l =~ /^ERROR at line/
            has_errors = true
            next
          end
          # After we find the ERROR at line, the next line contains the error
          # message, so we just want to consume it and then exit.
          # The line we care about will be in the buffer, so just break and join
          # the buffer.
          if has_errors
            break
          end
        end
        buffer.join("")
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
        @logfile = "#{@config.base_directory}/log/#{@log_dir}/#{File.basename(file)}"

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
          # Code compile errors never get here as they don't make sqlplus abort.
          # But if the user does not have privs to create the proc / trigger etc,
          # the code will abort to here via a insufficient privs error. Or if the code
          # file doesn't contain 'create or replace .... ' and just garbage it can get here.
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
