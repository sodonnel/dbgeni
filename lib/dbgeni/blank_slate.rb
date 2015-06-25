module DBGeni

  class ::BlankSlate
    KEEP_METHODS = [
                    :respond_to?,
                    :__id__,
                    :__send__,
                    :instance_eval,
                    :==,
                    :equal?,
                    :initialize,
                    :method_missing,
                    :instance_variable_set,
                    :send,
                    :alias_method
                   ]
    # In Ruby 1.8.7 the instance_methods call returns an array of
    # strings, but in later versions it returns an array of symbol.
    # This hack is here to convert the KEEP_METHODS array to strings
    # but only if required
    keepers = KEEP_METHODS
    if instance_methods.first.is_a?(String)
      keepers = KEEP_METHODS.map{|v| v.to_s}
    end
    suppress_warnings {
      (instance_methods - keepers).each do |m|
        undef_method(m)
      end
    }
  end

end
