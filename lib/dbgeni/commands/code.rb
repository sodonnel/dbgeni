if %w(-h --help).include? ARGV[0]
  puts <<-EOF
Usage: dbgeni code command <--environment-name env_name> <--config-file path/to/config> <--force>

If config-file is not specified, then a file called .dbgeni in the current directory will be
used if it exists, otherwise an error will occurr

If there is more than one environment defined in the config file, then environment-name must
be specified.

If --force is specified, all code files will be compiled and be marked as Completed even
if errors occur.

-e can be used as an abbreviation for --environment-name
-c can be used as an abbreviation for --config-file
-f can be used as an abbreviation for --force


Avaliable commands are:

Readonly
--------

list        Prints out all available code modules
            dbgeni code list --config-file /home/myapp/.dbgeni

current     Prints all code modules that have been applied to an environment
            dbgeni code applied --environment-name test --config-file /home/myapp/.dbgeni

outstanding Prints all code modules that have not been applied to an environment
            dbgeni code outstanding --environment-name test --config-file /home/myapp/.dbgeni


Destructive
-----------

apply       Apply code modules to the given environment. Can specify:

              all         Apply all code modules, even if they have already been applied.
              outstanding Apply only code modules that have changed since they were last applied
              specific code modules to apply

            dbgeni code apply all     --environment-name test --config-file /home/myapp/.dbgeni <--force>
            dbgeni code apply outstanding --environment-name test --config-file /home/myapp/.dbgeni <--force>
            dbgeni code apply insert_t1_proc.prc admin_package.pkb --environment-name test --config-file /home/myapp/.dbgeni <--force>

remove      Remove code modules from the given environment. Can specify:

            all      Remove all code modules installed
            specific code modules to remove

            dbgeni code remove all  --environment-name test --config-file /home/myapp/.dbgeni <--force>
            dbgeni code remove insert_t1_proc.prc admin_package.pkb --environment-name test --config-file /home/myapp/.dbgeni <--force>

EOF
  exit
end

command = ARGV.shift

installer = DBGeni::Base.installer_for_environment($config_file, $environment_name)
logger    = DBGeni::Logger.instance

begin
  case command
  when 'list', 'current', 'outstanding'
    method_mapper = {
      'list'             => :code,
      'current'          => :current_code,
      'outstanding'      => :outstanding_code
    }
    code = installer.send(method_mapper[command])
    if code.length == 0
      if command == 'list'
        logger.info "There are no code modules in #{installer.config.code_dir}"
      else
        logger.info "There are no code modules #{command}"
      end
      exit(0)
    end
    code.each do |c|
      puts c.to_s
    end
  when 'apply'
    sub_command = ARGV.shift
    case sub_command
    when 'all'
      installer.apply_all_code($force)
    when 'outstanding'
      installer.apply_outstanding_code($force)
    when /\.(#{DBGeni::Code::EXT_MAP.keys.join('|')})$/
      # The param list are specific code files. One is
      # stored in sub_command and the rest are in ARGV. Grab all params that match the
      # parameter name format
      files = ARGV.select{ |f| f =~ /\.(#{DBGeni::Code::EXT_MAP.keys.join('|')})$/ }
      files.unshift sub_command
      code = files.map {|f| DBGeni::Code.new(installer.config.code_dir, f)}
      # Now attempt to run each code file in
      code.each do |c|
        installer.apply_code(c, $force)
      end
    else
      logger.error "#{sub_command} is not a valid command"
    end

  when 'remove'
    sub_command = ARGV.shift
    case sub_command
    when 'all'
      installer.remove_all_code($force)
    when /\.(#{DBGeni::Code::EXT_MAP.keys.join('|')})$/
      files = ARGV.select{ |f| f =~ /\.(#{DBGeni::Code::EXT_MAP.keys.join('|')})$/ }
      files.unshift sub_command
      code = files.map {|f| DBGeni::Code.new(installer.config.code_dir, f)}
      # Now attempt to remove each code file
      code.each do |c|
        installer.remove_code(c, $force)
      end
    else
      logger.error "#{sub_command} is not a valid command"
    end
  else
    logger.error "#{command} is not a valid command"
  end
rescue DBGeni::NoOutstandingCode => e
  logger.info "There are no outstanding code modules to apply"
  exit(0)
rescue DBGeni::NoCodeFilesExist => e
  logger.error "There are no code files in the code_directory"
  exit(1)
rescue DBGeni::CodeApplyFailed => e
#  logger.error "There was a problem applying #{e.to_s}"
  exit(1)
rescue DBGeni::CodeModuleCurrent => e
  logger.error "The code module is already current #{e.to_s}"
  exit(1)
rescue DBGeni::CodeFileNotExist => e
  logger.error "The code file, #{e.to_s} does not exist"
  exit(1)
rescue DBGeni:: DatabaseNotInitialized => e
  logger.error "The database needs to be initialized with the command dbgeni initialize"
  exit(1)
rescue DBGeni::CodeDirectoryNotExist
  logger.error "The code directory does not exist"
  exit(1)
rescue DBGeni::DBCLINotOnPath
  logger.error "The command line interface for the database is not on the path (sqlite3, sqlplus)"
  exit(1)
end


exit(0)
