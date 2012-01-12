module DBGeni

  class FileConverter

    def self.convert(directory, file, config)
      fc = new(directory, file, config)
      fc.convert
    end

    def initialize(directory, file, config)
      @directory = directory
      @file      = file
      @config    = config
      create_temp
    end

    def convert
      original_file = File.join(@directory, @file)
      output_file   = File.join(@temp_dir, @file)
      begin
        of = File.open(output_file, 'w')
        File.foreach(original_file) do |line|
          # remove potential \r\n from dos files. isql chokes on these on linux
          # but not on windows.
          line.chomp!
          of.print line
          of.print "\n"
        end
      ensure
        of.close
      end
      output_file
    end

    private

    def create_temp
      @temp_dir = File.join(@config.base_directory, 'log', 'temp')
      FileUtils.mkdir_p(@temp_dir)
    end

  end

end
