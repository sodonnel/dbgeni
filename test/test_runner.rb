$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))

current_dir = File.expand_path(File.dirname(__FILE__))

require "dbgeni"
require 'test/unit'
require "mocha"


# Find all files that end in _test.rb and require them ...
files = Dir.entries(current_dir).grep(/^[^#].+_test\.rb$/).sort

%w(oracle sybase mysql cli).each do |db|
  if ARGV.include?(db) || ( ARGV.include?('all') && !ARGV.include?("no#{db}") )
    files += Dir.entries("#{current_dir}/#{db}").grep(/^[^#].+_test\.rb$/).sort.map{ |f| "#{db}/#{f}" }
  end
end

files.each do |f|
  # Sybase only works on Java :-/
  next if (RUBY_PLATFORM != 'java' && f =~ /sybase/)
#  next if (RUBY_PLATFORM != 'java' && f =~ /mysql/)
  puts f
  require File.join(current_dir, f)
end
