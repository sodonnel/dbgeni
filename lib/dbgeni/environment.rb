module DBGeni

  class Environment < BlankSlate

    def initialize(environment_name)
      @environment_name = environment_name
      @params           = Hash.new
      @loading          = true
    end

    def __enable_loading
      @loading = true
    end

    def __completed_loading
      @loading = false
    end

    def __is_loadable?
      @loading
    end

    def __environment_name
      @environment_name
    end

    def __merge_defaults(default_params)
      all_params = default_params.merge(@params)
      @params = all_params
    end

    def method_missing(name, *args, &block)
      str_name = name.to_s.gsub(/=$/, '')
      if __is_loadable?
        __load_parameter(str_name, *args)
      else
        __get_parameter(str_name, *args)
      end
    end

    def __to_s
      str = ''
      # get the longest key length to pad the keys
      max_length = @params.keys.map{ |k| k.length }.sort.last
      @params.keys.sort.each do |k|
        str << "#{k.ljust(max_length, ' ')} => #{@params[k]}\n"
      end
      str
    end

    private

    def __load_parameter(name, *args)
      if @params.has_key?(name)
        warn "Parameter #{name} was previously defined"
      end
      # TODO - Not sure whether to raise or just let it be nil
      #if nil == args[0]
      #  raise ""
      #end
      @params[name] = args[0] unless args[0] == ''
    end

    def __get_parameter(name, *args)
      unless @params.has_key?(name)
        # Password is a special case - if it is not defined it should be prompted for
        if name == 'password'
          puts "Please enter the password for #{@params['database']} in the #{@environment_name} environment\n"
          print "password: "
          password = gets.chomp
          @params[name] = password
          password
        end
      else
        @params[name]
      end
    end

  end

end

  # class Environment < BlankSlate

  #   def initialize(name)
  #     @__environment_name = name
  #   end

  #   def metaclass
  #     class << self
  #       self
  #     end
  #   end

  #   def lock
  #     metaclass.send(:alias_method, :__method_missing, :method_missing)
  #     metaclass.send(:undef_method, :method_missing)
  #   end

  #   def unlock
  #     metaclass.send(:alias_method, :method_missing, :__method_missing)
  #   end

  #   def method_missing(name, *args, &block)
  #     # TODO - add list of illegal param names (ie the list of kept methods
  #     #
  #     # if the method was a meth= type one, we need to get rid of the = sign
  #     #
  #     # This allows variables to be defined as
  #     #   param 'value'
  #     # or
  #     #   param = 'value'
  #     str_name = name.to_s.gsub(/=$/, '')
  #     method_name = ('@'+str_name).intern
  #     self.instance_variable_set(method_name, args[0])
  #     instance_eval("
  #       def #{str_name}(__param = nil)
  #         return @#{str_name} unless __param
  #         @#{str_name} = __param
  #       end
  #     ")
  #     metaclass.send(:alias_method, "#{str_name}=".intern, str_name.intern)
  #   end



    # Method to define a generic getter setter.
#def font_size(size = nil)
#  return @font_size unless size
#  @font_size = size
#  end
#alias_method :font_size=, :font_size

#  end
#end
