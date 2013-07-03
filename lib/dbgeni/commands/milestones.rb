if %w(-h --help).include? ARGV[0]
  puts <<-EOF

The milestone command can be used to list milestones.

Usage: dbgeni milestones command <--environment-name env_name> <--config-file path/to/config> <--force>

If config-file is not specified, then a file called .dbgeni in the current directory will be
used if it exists, otherwise an error will occurr

If there is more than one environment defined in the config file, then environment-name must
be specified.

If --force is specified, the migration will run to completion and be marked as Completed even
if errors occur.

-e can be used as an abbreviation for --environment-name
-c can be used as an abbreviation for --config-file
-f can be used as an abbreviation for --force


Avaliable commands are:

list      Prints out all available milestones
          dbgeni milestones list

EOF
  exit(0)
end

command = ARGV.shift

installer = nil
installer = $build_installer.call

begin
  case command
  when 'list'
    milestones = Dir.entries(installer.config.migration_directory).grep(/milestone$/)
    if milestones.length == 0
      puts "There are no milestones in the migrations_directory"
      exit(1)
    end
    milestones.each do |m|
      puts m.gsub(/\.milestone/, '')
    end
  else
    puts "#{command} is an invalid command"
    exit(1)
  end
end

