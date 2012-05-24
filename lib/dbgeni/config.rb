module DBGeni

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
    attr_reader   :environments
    attr_reader   :current_environment
    attr_reader   :migration_directory
    # ideally wnat code_dir to be code_directory, but then it clashes with the
    # setter used in the config file, so need to change it. Probably more sensible
    # like this than the migrations_directory vs migration_directory
    #                            _-_
    #
    attr_reader   :code_dir
    attr_reader   :db_type  # oracle, mysql, sqlite etc, default sqlite
    attr_reader   :db_table # defaults to dbgeni_migrations
    attr_reader   :config_file
    attr_reader   :base_directory

    DEFAULTS_ENV = '__defaults__'


    def initialize
      @migration_directory  = 'migrations'
      @code_dir             = 'code'
      @plugin_dir           =  nil
      @db_type              = 'sqlite'
      @db_table             = 'dbgeni_migrations'
      @base_dir             = '.'
      @environments         = Hash.new
    end


    def self.load_from_file(filename)
      cfg = self.new
      cfg.load_from_file(filename)
    end


    def load_from_file(filename)
      if filename == nil
        raise DBGeni::ConfigFileNotSpecified
      end
      raw_config = ''
      self.base_directory = File.expand_path(File.dirname(filename))
      @config_file        = File.expand_path(filename)
      begin
        File.open(@config_file) do |f|
          raw_config = f.read
        end
      rescue Errno::ENOENT
        raise DBGeni::ConfigFileNotExist, "#{@config_location} (expanded from #{filename}) does not exist"
      end
      load(raw_config)
    end


    # Normally this is assumed to be the location the config file is in.
    # All relative file operations come from this directory
    def base_directory=(dir)
      @base_directory = dir
      # If change the base directory, then unless migration dir is
      # an absolute path, it will need to change too.
      @migration_directory = File.join(@base_directory, @migration_directory) unless is_absolute_path?(@migration_dir)
      @code_dir            = File.join(@base_directory, @code_dir)   unless is_absolute_path?(@code_dir)
      if @plugin_dir
        @plugin_dir          = File.join(@base_directory, @plugin_dir) unless is_absolute_path?(@plugin_dir)
      end
    end


#    def get_environment(name)
#      if name == nil
#        # if there is only a single environment defined, then return it
#        if @environments.keys.length == 1
#          @environments[@environments.keys.first]
#        else
#          raise DBGeni::ConfigAmbiguousEnvironment, "More than one environment is defined"
#        end
#      else
#        unless @environments.has_key?(name)
#          raise DBGeni::EnvironmentNotExist
#        end
#        @environments[name]
#      end
#    end


    def env
      current_env
    end


    def current_env
      if @current_environment
        @environments[@current_environment]
      elsif @environments.keys.reject{|i| i == DEFAULTS_ENV}.length == 1
        @environments[@environments.keys.reject{|i| i == DEFAULTS_ENV}.first]
      else
        raise DBGeni::ConfigAmbiguousEnvironment, "More than one environment is defined"
      end
    end


    def set_env(name=nil)
      if name == nil
        valid_envs = @environments.keys.reject{|i| i == DEFAULTS_ENV}
        if valid_envs.length == 1
          @current_environment = valid_envs.first
        else
          raise DBGeni::ConfigAmbiguousEnvironment, "More than one environment is defined"
        end
      elsif @environments.has_key?(name)
        @current_environment = name
      else
        raise DBGeni::EnvironmentNotExist
      end
    end


    def load(raw_config, recursed=false)
      begin
        self.instance_eval(raw_config)
      rescue Exception => e
        raise DBGeni::ConfigSyntaxError, e.to_s
      end
      merge_defaults unless recursed
      self
    end

    def merge_defaults
      if @environments.has_key? DEFAULTS_ENV
        @environments.keys.each do |k|
          next if k == DEFAULTS_ENV
          @environments[k].__merge_defaults(@environments[DEFAULTS_ENV].__params)
        end
      end
    end

    def to_s
      str = ''
      str << "migrations_directory => #{@migration_directory}\n"
      @environments.keys.sort.each do |k|
        str << "\n\nEnvironment: #{k}\n"
        str <<     "=============#{(1..k.length).map do "=" end.join}\n\n"
        str << @environments[k].__to_s
      end
      str
    end

    ######################################
    # Methods below here are for the DSL #
    ######################################

    # mig_dir could be defined as a file in current directory 'migrations'
    # or it could be a relative directory './somedir/migrations'
    # or it could be a full path '/somedir/migrations' or in windows 'C:\somedir\migrations'
    # To use the migrations it needs to be expanded to a full path *somehow*.
    # If it begins / or <LETTER>:\ then assume its full path, otherwise concatenate
    # to the full path of the config file.
    def migrations_directory(*p)
      if p.length == 0
        @migration_directory
      else
        if is_absolute_path?(p[0])
          # it looks like an absolute path
          @migration_directory = p[0]
        else
          # it looks like a relative path
          if @base_directory
            @migration_directory = File.join(@base_directory, p[0])
          else
            @migration_directory = p[0]
          end
        end
      end
    end

    def code_directory(*p)
      if p.length == 0
        @code_dir
      else
        if is_absolute_path?(p[0])
          # it looks like an absolute path
          @code_dir = p[0]
        else
          # it looks like a relative path
          if @base_directory
            @code_dir = File.join(@base_directory, p[0])
          else
            @code_dir = p[0]
          end
        end
      end
    end

    def plugin_directory(*p)
      if p.length == 0
        @plugin_dir
      else
        if is_absolute_path?(p[0])
          # it looks like an absolute path
          @plugin_dir = p[0]
        else
          # it looks like a relative path
          if @base_directory
            @plugin_dir = File.join(@base_directory, p[0])
          else
            @plugin_dir = p[0]
          end
        end
      end
    end


    def database_type(*p)
      # TODO - consider putting validation here
      @db_type = p[0]
    end

    def database_table(*p)
      # TODO - consider putting validation here
      @db_table = p[0]
    end

    # For some reason I cannot work out, this method is never getting
    # call in the evaluated block. Ideally wanted to have migrations_directory
    # and migrations_directory= so that it doesn't matter which is called.
    # def migrations_directory=(value)
    #   puts "called the equals one"
    #   @migration_directory = value
    # end


    # Given a block of environment details, generate a new environment
    # object. eg
    # environment('some_name') do
    #   database  ''
    #   user      ''
    #   password  prompt
    #
    #   some_dir_path '/path_to_directory'
    def environment(name, &block)
      env = Environment.new(name)
      block.arity < 1 ? env.instance_eval(&block) : block.call(env)
      env.__completed_loading
      if @environments.has_key?(name)
        @environments[name].__merge_environment(env)
      else
        @environments[name] = env
      end
    end

    def defaults(&block)
      environment(DEFAULTS_ENV, &block)
    end


    def include_file(*p)
      file = p[0]
      if !is_absolute_path?(file)
        file = File.join(@base_directory, file)
      end
      begin
        raw_config = ''
        File.open(file) do |f|
          raw_config = f.read
        end
        self.load(raw_config)
      rescue Errno::ENOENT
        raise DBGeni::ConfigFileNotExist, "Included config #{file} does not exist"
      rescue DBGeni::ConfigSyntaxError
        raise DBGeni::ConfigSyntaxError,  "Included config #{file} contains errors: #{e.to_s}"
      end
    end

    private

    def is_absolute_path?(path)
      if path =~ /^\/|[a-zA-Z]:\\/
        true
      else
        false
      end
    end
  end
end
