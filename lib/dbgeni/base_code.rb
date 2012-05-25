module DBGeni
  module BaseModules
    module Code

      # This module isn't much good on its own, but it is here purely to
      # break up the code in the Base class. This module should be included
      # into base for code operations to work correctly

      def code
        @code_list ||= DBGeni::CodeList.new(@config.code_dir)
        @code_list.code
      end

      def current_code
        ensure_initialized
        code
        @code_list.current(@config, connection)
      end

      def outstanding_code
        ensure_initialized
        code
        @code_list.outstanding(@config, connection)
      end

      # Applying

      def apply_all_code(force=nil)
        ensure_initialized
        code_files = code
        if code_files.length == 0
          raise DBGeni::NoOutstandingCode
        end
        code_files.each do |c|
          apply_code(c, true) #force)
        end
      end

      def apply_outstanding_code(force=nil)
        ensure_initialized
        code_files = outstanding_code
        if code_files.length == 0
          raise DBGeni::NoOutstandingCode
        end
        code_files.each do |c|
          apply_code(c, force)
        end
      end

      def apply_code(code_obj, force=nil)
        ensure_initialized
        begin
          code_obj.apply!(@config, connection, force)
          if code_obj.error_messages
            # Oracle can apply procs that still have errors. This is expected. Other databases
            # have errors raised for invalid procs, except when force is on, so this logic is
            # for when they are being forced through.
            if @config.db_type == 'oracle'
              @logger.info "Applied #{code_obj.to_s} (with errors)\n\n#{code_obj.error_messages}\nFull errors in #{code_obj.logfile}\n\n"
            else
              @logger.error "Failed to apply #{code_obj.filename}. Errors in #{code_obj.logfile}\n\n#{code_obj.error_messages}\n\n"
            end
          else
            @logger.info "Applied #{code_obj.to_s}"
          end
        rescue DBGeni::CodeApplyFailed => e
          # The only real way code can get here is if the user had insufficient privs
          # to create the proc, or there was other bad stuff in the proc file.
          # In this case, dbgeni should stop - but also treat the error like a migration error
          # as the error message will be in the logfile in the format standard SQL errors are.
          @logger.error "Failed to apply #{code_obj.filename}. Errors in #{code_obj.logfile}\n\n#{code_obj.error_messages}\n\n"
          raise DBGeni::CodeApplyFailed, e.to_s
        end
      end

      def remove_all_code(force=nil)
        ensure_initialized
        code_files = code
        if code_files.length == 0
          raise DBGeni::NoCodeFilesExist
        end
        code_files.each do |c|
          remove_code(c, force)
        end
      end

      def remove_code(code_obj, force=nil)
        ensure_initialized
        begin
          code_obj.remove!(@config, connection, force)
          @logger.info "Removed #{code_obj.to_s}"
        rescue DBGeni::CodeRemoveFailed => e
          # Not sure if the code can even get here. Many if timeout waiting for lock on object?
          # In this case, dbgeni should stop - but also treat the error like a migration error

          # TODO - not sure this is even correct - dropping code doesn't create a logfile ...
          @logger.error "Failed to remove #{code_obj.filename}. Errors in #{code_obj.logfile}"
          raise DBGeni::CodeRemoveFailed
        end
      end


    end
  end
end
