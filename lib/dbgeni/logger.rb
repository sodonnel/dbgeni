module DBGeni

  class Logger

    def self.instance(location=nil)
      @@suppress_stdout ||= false
      @@singleton_instance ||= self.new(location)
    end

    def self.suppress_stdout
      @@suppress_stdout = true
    end

    def info(msg)
      write_msg(msg)
    end

    def error(msg)
      write_msg("ERROR - #{msg}")
    end

    def close
      if @fh && !@fh.closed?
        @fh.close
      end
      @@singleton_instance = nil
    end

    # This could be done in the initialize block, but then even for
    # non destructive commands, there would be a detailed log dir
    # created, so only create the dir when the directory is asked for.
    def detailed_log_dir
      FileUtils.mkdir_p(File.join(@log_location, @detailed_log_dir))
      File.join(@log_location, @detailed_log_dir)
    end

    def reset_detailed_log_dir
      @detailed_log_dir = Time.now.strftime('%Y%m%d%H%M%S')
    end

    private

    def write_msg(msg, echo=true)
      if @fh && !@fh.closed?
        @fh.puts "#{Time.now.strftime('%Y%m%d %H:%M:%S')} - #{msg}"
      end
      unless @@suppress_stdout
        puts msg
      end
    end

    def initialize(location=nil)
      # If location is nil, then error
      @log_location = File.expand_path(location)
      if @log_location
        FileUtils.mkdir_p(location)
        @fh = File.open("#{location}/log.txt", 'a')
        @fh.puts("\n\n\n###################################################")
        @fh.puts("dbgeni initialized")
        reset_detailed_log_dir
        @fh.puts("Detailed log files will be written in #{File.join(@log_location, @detailed_log_dir)}")
      end
    end

  end

end
