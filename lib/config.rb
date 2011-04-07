module DBInst
  class Config
    attr_accessor :migration_dir, :plsq_dir, :environments

    def initialize(config_filename)
      @config_filename = config_filename
      @migration_dir   = 'migrations'
      @plsql_dir       = 'plsql'
      @environments    = Hash.new
    end

    def load_config
      raw_config = '' #Read from file
      self.instance_eval(raw_config)
    end

    # Given a block of environment details, generate a new environment
    # object. eg
    # environment('some_name') do
    #   database  ''
    #   user      ''
    #   password  prompt
    #
    #   some_dir_path '/path_to_directory'
    def environment(name, &blk)
      if @environments.exists(name)
        warn "Environment #{name} has been previously defined"
      end
      env = Environment.new(name)
      block.arity < 1 ? env.instance_eval(&block) : block.call(env)
      @environments[name] = env
    end
  end
end
