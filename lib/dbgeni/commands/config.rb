if %w(-h --help).include? ARGV[0]
  puts <<-EOF
Usage:
By default, dbgeni will search in the current directory for a config file
called .dbgeni

To list all the config for all environments:
  dbgeni config

To use a different config_file, specify the config_file switch:
  dbgeni config environment_name --config_file </path/to/config/file>
EOF
  exit(0)
end

if ! File.exists?($config_file)
  puts "error: The config file #{$config_file} does not exist"
  exit(1)
end

require 'dbgeni'

begin
  cfg = DBGeni::Config.load_from_file($config_file)
rescue DBGeni::ConfigSyntaxError => e
  puts "There is an error in the config file: #{e.to_s}"
end
puts "-----------------------------\n"
puts "| Current Parameter Details |\n"
puts "-----------------------------\n\n"
puts cfg.to_s

exit(0)





