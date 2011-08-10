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

  def test_missing_environment_raises_exception
    cfg = DBInst::Config.new
    cfg.load("environment('foo') { } \n environment('bar') { }")
    assert_raises(DBInst::EnvironmentNotExist) do
      cfg.get_environment('not_there')
    end
  end

  def test_correct_environment_is_returned
    cfg = DBInst::Config.new
    cfg.load("environment('foo') { } \n environment('bar') { }")
    env = cfg.get_environment('foo')
    assert_equal('foo', env.__environment_name)
  end

  def test_only_environment_is_returned_when_no_param
    cfg = DBInst::Config.new
    cfg.load("environment('foo') { }")
    env = cfg.get_environment(nil)
    assert_equal('foo', env.__environment_name)
  end

  def test_exception_when_no_environment_passed_and_many_defined
    cfg = DBInst::Config.new
    cfg.load("environment('foo') { }\n environment('bar') { }")
    assert_raises( DBInst::ConfigAmbiguousEnvironment) do
      env = cfg.get_environment(nil)
    end
  end

  def test_migrations_directory_defaults
    cfg = DBInst::Config.new
    cfg.load("environment('foo') { }\n environment('bar') { }")
    assert_equal('migrations', cfg.migration_directory)
  end

  def test_migrations_dir_settable_via_config
    cfg = DBInst::Config.new
    cfg.load("migrations_directory 'other_dir'\nenvironment('foo') { }\n environment('bar') { }")
    assert_equal('other_dir', cfg.migration_directory)
  end

  def test_absolution_migrations_dir_not_modified_windows
    cfg = DBInst::Config.new
    cfg.base_directory = "c:\\somedir\\"
    # !! need to escape backslashes as they are escape character!
    cfg.load("migrations_directory 'c:\\other_dir'\nenvironment('foo') { }\n environment('bar') { }")
    assert_equal('c:\other_dir', cfg.migration_directory)
  end

  def test_absolution_migrations_dir_not_modified_unix
    cfg = DBInst::Config.new
    cfg.base_directory = "c:\\somedir\\"
    cfg.load("migrations_directory '/other_dir'\nenvironment('foo') { }\n environment('bar') { }")
    assert_equal('/other_dir', cfg.migration_directory)
  end

  def test_relative_migrations_dir_added_to_base_windows
    cfg = DBInst::Config.new
    cfg.base_directory = "c:\\somedir\\"
    cfg.load("migrations_directory 'other_dir'\nenvironment('foo') { }\n environment('bar') { }")
    assert_equal("c:\\somedir\\other_dir", cfg.migration_directory)
  end

  def test_relative_migrations_dir_added_to_base_unix
    cfg = DBInst::Config.new
    cfg.base_directory = '/somedir'
    cfg.load("migrations_directory 'other_dir'\nenvironment('foo') { }\n environment('bar') { }")
    assert_equal('/somedir/other_dir', cfg.migration_directory)
  end

  def test_migrations_dir_changes_when_base_dir_changed
    cfg = DBInst::Config.new
    cfg.base_directory = '/somedir'
    assert_equal('/somedir/migrations', cfg.migration_directory)
  end



end
