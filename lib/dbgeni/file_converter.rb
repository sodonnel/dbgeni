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
      File.join(@directory, @file)
    end

    private

    def create_temp
      @temp_dir = File.join(@config.base_directory, 'log', 'temp')
      FileUtils.mkdir_p(@temp_dir)
    end
  end

end
