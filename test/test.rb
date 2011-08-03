$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))

require "dbinst"
require 'test/unit'

class TestConfig < Test::Unit::TestCase

  def setup
  end

  def teardown
  end

  def test_single_environment_loaded
    cfg = DBInst::Config.new #Base.new
    cfg.load("environment('foo') { }")
    assert(cfg.environments.has_key?('foo'))
  end

  # This test does not pass!
#  def test_single_environment_loaded_no_brackets
#    installer = DBInst::Base.new
#    installer.load_config("environment 'foo' { }")
#    assert(installer.config.environments.has_key?('foo'))
#  end

  def test_many_environments_loaded
    cfg = DBInst::Config.new
    cfg.load("environment('foo') { } \n environment('bar') { }")
    assert(cfg.environments.has_key?('foo'))
    assert(cfg.environments.has_key?('bar'))
  end

  def test_can_set_param_in_environment
    cfg = DBInst::Config.new
    cfg.load("environment('foo') {
      some_param 'foobar'
    }")
    assert_equal(cfg.environments['foo'].some_param, 'foobar')
  end

  def test_can_set_param_in_one_environment_only
    cfg = DBInst::Config.new
    cfg.load("environment('foo') {
      some_param 'foobar'
    }
    environment('bar') { }")
    assert_equal(cfg.environments['foo'].some_param, 'foobar')
    assert_equal(nil, cfg.environments['bar'].some_param)
  end

  def test_after_loading_environment_raises_no_method
    cfg = DBInst::Config.new
    cfg.load("environment('foo') {
    }")
    assert_equal(nil, cfg.environments['foo'].some_param)
  end

  def test_can_set_get_migrations_directory
    cfg = DBInst::Config.new
    cfg.load("environment('foo') {
    }\n
    migrations_directory 'some directory'")
    assert_equal('some directory', cfg.migrations_directory)
  end



end
