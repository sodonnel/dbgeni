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
    attr_reader   :db_type  # oracle, mysql, sqlite etc
    attr_reader   :db_table # defaults to dbgeni_migrations
    attr_reader   :config_file
    attr_reader   :base_directory

    def initialize
      @migration_directory  = 'migrations'
      @db_type              = 'oracle'
      @db_table             = 'dbgeni_migrations'
      @environments         = Hash.new
    end


    def self.load_from_file(filename)
      cfg = self.new
      cfg.load_from_file(filename)
    end


    def load_from_file(filename)
      raw_config = ''
      self.base_directory = File.expand_path(File.dirname(filename))
      @config_file     = File.expand_path(filename)
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
      if is_absolute_path?(@migration_dir)
        # TODO - need to take off the actual migration directory and join to new base_dir
      else
        @migration_directory = File.join(@base_directory, @migration_directory)
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
      elsif @environments.keys.length == 1
        @environments[@environments.keys.first]
      else
        raise DBGeni::ConfigAmbiguousEnvironment, "More than one environment is defined"
      end
    end


    def set_env(name=nil)
      if name == nil
        if @environments.keys.length == 1
          @current_environment = @environments.keys.first
        else
          raise DBGeni::ConfigAmbiguousEnvironment, "More than one environment is defined"
        end
      elsif @environments.has_key?(name)
        @current_environment = name
      else
        raise DBGeni::EnvironmentNotExist
      end
    end


    def load(raw_config)
      self.instance_eval(raw_config)
      self
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
      if @environments.has_key?(name)
        warn "Environment #{name} has been previously defined"
      end
      env = Environment.new(name)
      block.arity < 1 ? env.instance_eval(&block) : block.call(env)
      env.__completed_loading
      @environments[name] = env
    end

    def global_parameters(name, &block)
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
