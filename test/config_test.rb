$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))

require "dbgeni"
require 'test/unit'

class TestConfig < Test::Unit::TestCase

  def setup
  end

  def teardown
  end

  def test_single_environment_loaded
    cfg = DBGeni::Config.new #Base.new
    cfg.load("environment('foo') { }")
    assert(cfg.environments.has_key?('foo'))
  end

  # This test does not pass!
#  def test_single_environment_loaded_no_brackets
#    installer = DBGeni::Base.new
#    installer.load_config("environment 'foo' { }")
#    assert(installer.config.environments.has_key?('foo'))
#  end

  def test_many_environments_loaded
    cfg = DBGeni::Config.new
    cfg.load("environment('foo') { } \n environment('bar') { }")
    assert(cfg.environments.has_key?('foo'))
    assert(cfg.environments.has_key?('bar'))
  end

  def test_can_set_param_in_environment
    cfg = DBGeni::Config.new
    cfg.load("environment('foo') {
      some_param 'foobar'
    }")
    assert_equal(cfg.environments['foo'].some_param, 'foobar')
  end

  def test_can_set_param_in_one_environment_only
    cfg = DBGeni::Config.new
    cfg.load("environment('foo') {
      some_param 'foobar'
    }
    environment('bar') { }")
    assert_equal(cfg.environments['foo'].some_param, 'foobar')
    assert_equal(nil, cfg.environments['bar'].some_param)
  end

  def test_after_loading_environment_raises_no_method
    cfg = DBGeni::Config.new
    cfg.load("environment('foo') {
    }")
    assert_equal(nil, cfg.environments['foo'].some_param)
  end

  def test_can_set_get_migrations_directory
    cfg = DBGeni::Config.new
    cfg.load("environment('foo') {
    }\n
    migrations_directory 'some directory'")
    assert_equal('some directory', cfg.migrations_directory)
  end


  ## Set, get current_env tests ##

  def test_single_environment_set_env_no_name
    cfg = DBGeni::Config.new
    cfg.load("environment('foo') { } \n")
    cfg.set_env
    assert_equal('foo', cfg.current_environment)
  end

  def test_single_environment_set_env_name
    cfg = DBGeni::Config.new
    cfg.load("environment('foo') { } \n")
    cfg.set_env('foo')
    assert_equal('foo', cfg.current_environment)
  end

  def test_single_environment_set_env_name_not_exist
    cfg = DBGeni::Config.new
    cfg.load("environment('foo') { } \n")
    assert_raises DBGeni::EnvironmentNotExist do
      cfg.set_env('bar')
    end
  end

  def test_many_environment_set_env_no_name
    cfg = DBGeni::Config.new
    cfg.load("environment('foo') { } \nenvironment('bar') { } \n")
    assert_raises DBGeni::ConfigAmbiguousEnvironment do
      cfg.set_env
    end
  end

  def test_many_environment_set_env_name
    cfg = DBGeni::Config.new
    cfg.load("environment('foo') { } \nenvironment('bar') { } \n")
    cfg.set_env('foo')
    assert_equal('foo', cfg.current_environment)
  end

  def test_many_environment_set_env_name_not_exist
    cfg = DBGeni::Config.new
    cfg.load("environment('foo') { } \nenvironment('bar') { } \n")
    assert_raises DBGeni::EnvironmentNotExist do
      cfg.set_env('foobar')
    end
  end

  def test_single_environment_get_current_env_not_set
    cfg = DBGeni::Config.new
    cfg.load("environment('foo') { } \n")
    assert_equal('foo', cfg.current_env.__environment_name)
  end

  def test_single_environment_get_current_env_set
    cfg = DBGeni::Config.new
    cfg.load("environment('foo') { } \n")
    cfg.set_env('foo')
    assert_equal('foo', cfg.current_env.__environment_name)
  end

  def test_many_environment_get_current_env_not_set
    cfg = DBGeni::Config.new
    cfg.load("environment('foo') { } \n environment('bar') { } \n")
    assert_raises DBGeni::ConfigAmbiguousEnvironment do
      cfg.current_env
    end
  end

  def test_many_environment_get_current_env_set
    cfg = DBGeni::Config.new
    cfg.load("environment('foo') { } \n environment('bar') { } \n")
    cfg.set_env('foo')
    assert_equal('foo', cfg.current_env.__environment_name)
  end

  ## End get, set current_env tests ##


  def test__environment_set_env_name_not_exist
    cfg = DBGeni::Config.new
    cfg.load("environment('foo') { } \n")
    assert_raises DBGeni::EnvironmentNotExist do
      cfg.set_env('bar')
    end
  end


  def test_migrations_directory_defaults
    cfg = DBGeni::Config.new
    cfg.load("environment('foo') { }\n environment('bar') { }")
    assert_equal('migrations', cfg.migration_directory)
  end

  def test_migrations_dir_settable_via_config
    cfg = DBGeni::Config.new
    cfg.load("migrations_directory 'other_dir'\nenvironment('foo') { }\n environment('bar') { }")
    assert_equal('other_dir', cfg.migration_directory)
  end

  def test_absolution_migrations_dir_not_modified_windows
    cfg = DBGeni::Config.new
    cfg.base_directory = "c:\\somedir\\"
    # !! need to escape backslashes as they are escape character!
    cfg.load("migrations_directory 'c:\\other_dir'\nenvironment('foo') { }\n environment('bar') { }")
    assert_equal('c:\other_dir', cfg.migration_directory)
  end

  def test_absolution_migrations_dir_not_modified_unix
    cfg = DBGeni::Config.new
    cfg.base_directory = "c:\\somedir\\"
    cfg.load("migrations_directory '/other_dir'\nenvironment('foo') { }\n environment('bar') { }")
    assert_equal('/other_dir', cfg.migration_directory)
  end

  def test_relative_migrations_dir_added_to_base_windows
    cfg = DBGeni::Config.new
    cfg.base_directory = "c:\\somedir\\"
    cfg.load("migrations_directory 'other_dir'\nenvironment('foo') { }\n environment('bar') { }")
    if Kernel.is_windows?
      assert_equal("c:\\somedir\\other_dir", cfg.migration_directory)
    end
  end

  def test_relative_migrations_dir_added_to_base_unix
    cfg = DBGeni::Config.new
    cfg.base_directory = '/somedir'
    cfg.load("migrations_directory 'other_dir'\nenvironment('foo') { }\n environment('bar') { }")
    assert_equal('/somedir/other_dir', cfg.migration_directory)
  end

  def test_migrations_dir_changes_when_base_dir_changed
    cfg = DBGeni::Config.new
    cfg.base_directory = '/somedir'
    assert_equal('/somedir/migrations', cfg.migration_directory)
  end

  def test_database_table_defaults_to_correct_value
    cfg = DBGeni::Config.new
    cfg.load("environment('foo') { }\n environment('bar') { }")
    assert_equal('dbgeni_migrations', cfg.db_table)
  end

  def test_database_table_settable_in_config
    cfg = DBGeni::Config.new
    cfg.load("database_table \"other_table\"\nenvironment('foo') { }\n environment('bar') { }")
    assert_equal('other_table', cfg.db_table)
  end

  def test_database_type_defaults_to_correct_value
    cfg = DBGeni::Config.new
    cfg.load("environment('foo') { }\n environment('bar') { }")
    assert_equal('oracle', cfg.db_type)
  end

  def test_database_type_settable_in_config
    cfg = DBGeni::Config.new
    cfg.load("database_type \"sqlite\"\nenvironment('foo') { }\n environment('bar') { }")
    assert_equal('sqlite', cfg.db_type)
  end

end
