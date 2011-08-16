$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))

current_dir = File.expand_path(File.dirname(__FILE__))

require "dbgeni"
require 'test/unit'

# Find all files that end in _test.rb and require them ...
files = Dir.entries(current_dir).grep(/^[^#].+_test\.rb$/).sort
files.each do |f|
  require File.join(current_dir, f)
end
