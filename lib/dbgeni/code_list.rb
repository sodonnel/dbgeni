module DBGeni

  class CodeList

    attr_reader :code
    attr_reader :code_directory

    def initialize(code_directory)
      @code_directory = code_directory
      file_list
    end

    def current(config, connection)
      @code.select{ |c| c.current?(config, connection) }
    end

    def outstanding(config, connection)
      @code.select{ |c| ! c.current?(config, connection) }
    end

    def list(list_of_code, config, connection)
      valid_code = []
      list_of_code.each do |c|
        code_obj = Code.new(config.code_dir, c)
        if i = @code.index(code_obj)
          valid_code.push @code[i]
        else
          raise DBGeni::CodeFileNotExist, c
        end
      end
      valid_code.sort {|x,y|
        x.sort_field <=> y.sort_field
      }
    end

    private

    def file_list
      begin
        # The allowed list of code filetypes is in the Code class.
        # Use that list to form a dynamic regex so all the extensions are only in one place.
        extensions = DBGeni::Code::EXT_MAP.keys
        files = Dir.entries(@code_directory).grep(/\.(#{extensions.join('|')})$/).sort
      rescue Exception => e
        raise DBGeni::CodeDirectoryNotExist, "Code directory: #{@code_directory}"
      end
      @code = Array.new
      files.each do |f|
        @code.push DBGeni::Code.new(@code_directory, f)
        @code.sort! {|x,y|
          x.sort_field <=> y.sort_field
        }
      end
    end

  end

end


