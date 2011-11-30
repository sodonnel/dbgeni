module DBGeni
  module Migrator

    class Sybase < DBGeni::Migrator::MigratorInterface

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
        # The first error is the one to report - with sybase isql doesn't stop on errors
        # The error lines tend to look like:
        # Msg 156, Level 15, State 2:
        # Server 'WW637L18714A', Line 2:
        # Incorrect syntax near the keyword 'table'.
        begin
          fh = File.open(@logfile, 'r')
          # search for a line starting Msg or Error and then grab the next 2 lines to make up the error.
          while (l = fh.readline)
            if l =~ /^(Msg|Error)\s\d+/
              error = l
              break
            end
          end
          unless error == ''
            # if an error was found, add the next two lines to the error message
            error << fh.readline
            error << fh.readline
          end
        rescue ::EOFError
          # reached the end of file before a full error message was found ...
          # Just catch and move on ...
        ensure
          fh.close if fh
        end
        error
      end

     # def verify(migration)
     # end

      def compile(code)
        run_in_client(File.join(@config.code_directory, code.filename), false, true)
      end

      def remove(code)
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
        # -e echos input
        # -w200 - sets line width to 250 from the default of 80
        response = system("isql -U#{z.username} -P#{z.password} -S#{z.sybase_service} -D#{z.database} -e -w 200 -i#{file} -o#{logfile}")

        has_errors = false
        unless force
          # For empty migrations, sometimes no logfile?
          if File.exists? @logfile
            File.open(@logfile, 'r').each do |l|
              if l =~ /^(Msg|Error)\s\d+/ 
                has_errors = true
                break
              end
            end
          end
        end

        if has_errors or !response
          unless force
            raise DBGeni::MigrationContainsErrors
          end
        end
      end

      def ensure_executable_exists
        unless Kernel.executable_exists?('isql')
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
