module DBInst
  class Environment < BlankSlate

    def initialize(name)
      @__environment_name = name
    end

    def metaclass
      class << self
        self
      end
    end

    def lock
      metaclass.send(:alias_method, :__method_missing, :method_missing)
      metaclass.send(:undef_method, :method_missing)
    end

    def unlock
      metaclass.send(:alias_method, :method_missing, :__method_missing)
    end

    def method_missing(name, *args, &block)
      # TODO - add list of illegal param names (ie the list of kept methods
      #
      # if the method was a meth= type one, we need to get rid of the = sign
      #
      # This allows variables to be defined as
      #   param 'value'
      # or
      #   param = 'value'
      str_name = name.to_s.gsub(/=$/, '')
      method_name = ('@'+str_name).intern
      self.instance_variable_set(method_name, args[0])
      instance_eval("
        def #{str_name}(__param = nil)
          return @#{str_name} unless __param
          @#{str_name} = __param
        end
      ")
#  alias_method :#{str_name}=, :#{str_name}
    end



    # Method to define a generic getter setter.
#def font_size(size = nil)
#  return @font_size unless size
#  @font_size = size
#  end
#alias_method :font_size=, :font_size

  end
end
