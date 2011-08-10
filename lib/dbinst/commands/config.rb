if %w(-h --help).include? ARGV[0]
  puts <<-EOF
Usage:
By default, dbinst will search in the current directory for a config file
called .dbinst

To list all the config for all environments:
  dbinst config environment_name

To list the config for only a specific environment:
  dbinst config environment_name

To use a different config_file, specify the config_file switch:
  dbinst config environment_name --config_file </path/to/config/file>
EOF
  exit(0)
end

if ! File.exists?($config_file)
  puts "error: The config file #{$config_file} does not exist"
  exit(1)
end

require 'dbinst'

cfg = DBInst::Config.load_from_file($config_file)
puts "-----------------------------\n"
puts "| Current Parameter Details |\n"
puts "-----------------------------\n\n"
puts cfg.to_s

exit(0)



