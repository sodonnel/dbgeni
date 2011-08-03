module DBInst

  # Config understands the following:

  # migrations_directory 'value' # This will be checked to ensure its a valid dir
  #                              # and defaults to 'migrations'
  # environment('development') {
  #   username 'user' # this must be here, or it will error
  #   database 'MYDB.WORLD'     # this must be here, or it will error. For Oracle, this is the TNS Name
  #   password ''     # If this value is missing, it will be promoted for if the env is used.
  # }
  #
  # environment('other environment') {
  #   username '' # the environment block can be repeated for many environments
  # }
  #
  # global_parameters { # These are common parameters to all environments, but they can be
  #                     # overriden. Basically take global, merge in environment
  #   param_name 'value'
  # }

  class Config
    attr_accessor :environments

    def initialize
#      @config_filename = config_filename
      @migration_directory  = 'migrations'
      @environments         = Hash.new
    end

    def self.load_from_file(filename)
      cfg = self.new
      cfg.load_from_file(filename)
    end

    def load_from_file(filename)
      raw_config = ''
      File.open(filename) do |f|
        raw_config = f.read
      end
      load(raw_config)
    end

    ## TODO remove this method ...
    def load_config_from_file
      raw_config = ''
      File.open("./.dbinst") do |f|
        raw_config = f.read
      end
      load(raw_config)
    end

    def load(raw_config)
      self.instance_eval(raw_config)
      self
    end

    def to_s
      str = ''
      str << "migrations_directory => #{@migration_directory}\n"
      @environments.keys.sort.each do |k|
        str << "Environment: #{k}\n"
        @environments[k].keys.sort.each do |ek|
          str << "#{ek} => #{@environments[k][ek]}\n"
        end
      end
      str
    end

    # Methods below here are for the DSL

    def migrations_directory(*p)
      if p.length == 0
        @migration_directory
      else
        @migration_directory = p[0]
      end
    end

    # For some reason I cannot work out, this method is never getting
    # call in the evaluated block
#    def migrations_directory=(value)
#      puts "called the equals one"
#      @migration_directory = value
#    end


    # Given a block of environment details, generate a new environment
    # object. eg
    # environment('some_name') do
    #   database  ''
    #   user      ''
    #   password  prompt
    #
    #   some_dir_path '/path_to_directory'
    def environment(name, &block)
      if @environments.has_key?(name)
        warn "Environment #{name} has been previously defined"
      end
      env = Environment.new(name)
      block.arity < 1 ? env.instance_eval(&block) : block.call(env)
      env.lock
      @environments[name] = env
    end

    def global_parameters(name, &block)
    end
  end
end
