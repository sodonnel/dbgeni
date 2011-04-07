$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))

require "dbinst"
require 'test/unit'

class TestConfig < Test::Unit::TestCase

  def setup
  end

  def teardown
  end

  def test_single_environment_loaded
    installer = DBInst::Base.new
    installer.load_config("environment('foo') { }")
    assert(installer.config.environments.has_key?('foo'))
  end

  def test_many_environments_loaded
    installer = DBInst::Base.new
    installer.load_config("environment('foo') { } \n environment('bar') { }")
    assert(installer.config.environments.has_key?('foo'))
    assert(installer.config.environments.has_key?('bar'))
    assert(installer.config.environments.has_key?('foof'))
  end
end
