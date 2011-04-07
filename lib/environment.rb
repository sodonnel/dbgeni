module DBInst
  class Environment < BlankSlate

    def initialize(name)
      @__environment_name = name
    end

    def method_missing(name, *args, &block)
    end

# Method to define a generic getter setter.
#def font_size(size = nil)
#  return @font_size unless size
#  @font_size = size
#  end
#alias_method :font_size=, :font_size

  end
end
