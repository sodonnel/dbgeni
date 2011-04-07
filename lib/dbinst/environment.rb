module DBInst
  class Environment < BlankSlate

    def initialize(name)
      @__environment_name = name
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
      str_name = method_sym.to_s.gsub(/=$/, '')
      method_name = ('@'+str_name).intern
      self.instance_variable_set(method_name, arguments[0])
      metaclass.send :attr_reader, str_name
      self.instance_eval("
        def #{method_name}(__param = nil)
          return @#{method_name} unless __param
          @#{method_name} = __param
        end")
    end

# Method to define a generic getter setter.
#def font_size(size = nil)
#  return @font_size unless size
#  @font_size = size
#  end
#alias_method :font_size=, :font_size

  end
end
