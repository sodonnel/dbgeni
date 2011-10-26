# hack to get the CLI working witout being properly installed as a gem
$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "lib"))

$config_file      = './.dbgeni'
$environment_name = nil
$force            = false

if index = ARGV.index('--config-file') or index = ARGV.index('-c')
  unless ARGV[index+1]
    puts "error: --config-file switch present, but no file specified"
    exit
  end
  $config_file = ARGV[index+1]
  # remove all references to config file from the argument list
  ARGV.delete_at(index)
  ARGV.delete_at(index)
end

if index = ARGV.index('--environment-name') or index = ARGV.index('-e')
  unless ARGV[index+1]
    puts "error: --environment-name switch present, but no environment specified"
    exit
  end
  $environment_name = ARGV[index+1]
  # remove all references to config file from the argument list
  ARGV.delete_at(index)
  ARGV.delete_at(index)
end

if index = ARGV.index('--force') or index = ARGV.index('-f')
  $force = true
  ARGV.delete_at(index)
end

require 'dbgeni'

begin
  require 'dbgeni/commands/commands'
rescue DBGeni::ConfigSyntaxError => e
  puts "There is an error in the config file: #{e.to_s}"
  exit(1)
rescue DBGeni::ConfigFileNotExist => e
  puts "The config file #{$config_file} does not exist"
  exit(1)
rescue DBGeni::ConfigFileNotSpecified => e
  puts "No config file was specified"
  exit(1)
rescue DBGeni::ConfigAmbiguousEnvironment => e
  puts "No environment specified and config file defines more than one environment"
  exit(1)
rescue DBGeni::EnvironmentNotExist => e
  puts "The environment #{$environment_name} does not exist"
  exit(1)
rescue DBGeni::DBConnectionError => e
  puts "Failed to establish databse connection: #{e.to_s}"
  exit(1)
end

