module DBGeni

  class Logger

    def self.instance(location=nil)
      @@singleton_instance ||= self.new(location)
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

    private

    def write_msg(msg)
      if @fh && !@fh.closed?
        @fh.puts "#{Time.now.strftime('%Y%m%d %H:%M:%S')} - #{msg}"
      end
      puts msg
    end

    def initialize(location=nil)
      # If location is nil, then error
      @log_location = location
      if @log_location
        FileUtils.mkdir_p(location)
        @fh = File.open("#{location}/log.txt", 'a')
      end
    end

  end

end
