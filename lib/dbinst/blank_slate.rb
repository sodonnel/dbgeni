module DBInst

  class BlankSlate
    KEEP_METHODS = %w"__id__ __send__ instance_eval == equal? initialize method_missing instance_variable_set"
    (instance_methods - KEEP_METHODS).each do |m|
      undef_method(m)
    end
  end

end
