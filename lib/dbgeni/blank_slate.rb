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
    suppress_warnings {
      (instance_methods - KEEP_METHODS).each do |m|
        undef_method(m)
      end
    }
  end

end