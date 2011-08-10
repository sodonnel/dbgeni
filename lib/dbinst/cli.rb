# hack to get the CLI working witout being properly installed as a gem
$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "lib"))

$config_file      = './.dbinst'
$environment_name = nil

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

require 'dbinst/commands/commands'
