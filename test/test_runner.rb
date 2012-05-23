$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))

current_dir = File.expand_path(File.dirname(__FILE__))

require "dbgeni"
require 'test/unit'
require "mocha"

no_cli = false
if ARGV.include?('--no-cli')
  ARGV.delete('--no-cli')
  no_cli = true
end


# Find all files that end in _test.rb and require them ...
files = Dir.entries(current_dir).grep(/^[^#].+_test\.rb$/).sort
files.each do |f|
  next if (no_cli && f =~ /^cli/)
  next if (RUBY_PLATFORM != 'java' && f =~ /sybase/)
#  next if (f =~ /sybase/)
  next if (RUBY_PLATFORM != 'java' && f =~ /mysql/)
  puts f
  require File.join(current_dir, f)
end
