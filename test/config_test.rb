$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$:.unshift File.expand_path(File.dirname(__FILE__))

require "helper"
require "dbgeni"
require 'test/unit'

class TestConfig < Test::Unit::TestCase

  include TestHelper

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

  def test_single_environment_with_default_set_env_no_name
    cfg = DBGeni::Config.new
    cfg.load("environment('foo') { } \n defaults { p1 'a' }")
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

  def test_single_environment_with_defaults_get_current_env_not_set
    cfg = DBGeni::Config.new
    cfg.load("environment('foo') { } \n defaults { p1 'a' }")
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

  def test_specifying_same_environment_twice_merges
    cfg = DBGeni::Config.new
    cfg.load("environment('foo') {
                p1 'hello'
                p2 'there'
              } \n
              environment('foo') {
                p2 'bob'
                p3 'jimmy'
             } \n")
    assert_equal('hello', cfg.env.p1)
    assert_equal('bob',   cfg.env.p2)
    assert_equal('jimmy', cfg.env.p3)
  end

  def test_specifying_defaults_sets_internal_environment
    cfg = DBGeni::Config.new
    cfg.load("defaults {
                p1 'hello'
                p2 'there'
              } \n
              defaults {
                p2 'bob'
                p3 'jimmy'
             } \n")
    cfg.set_env('__defaults__')
    assert_equal('hello', cfg.env.p1)
    assert_equal('bob',   cfg.env.p2)
    assert_equal('jimmy', cfg.env.p3)
  end

  def test_defaults_merged_when_defined_at_start
    cfg = DBGeni::Config.new
    cfg.load("defaults {
               p1 'hello'
             } \n
             environment('foo') {
               p2 'bob'
            } \n")
    assert_equal('hello', cfg.env.p1)
    assert_equal('bob',   cfg.env.p2)
  end

  def test_defaults_merged_when_defined_at_end
    cfg = DBGeni::Config.new
    cfg.load("environment('foo') {
               p2 'bob'
            } \n
            defaults {
               p1 'hello'
             } \n")
    assert_equal('hello', cfg.env.p1)
    assert_equal('bob',   cfg.env.p2)
  end


  ## End get, set current_env tests ##


  def test_environment_set_env_name_not_exist
    cfg = DBGeni::Config.new
    cfg.load("environment('foo') { } \n")
    assert_raises DBGeni::EnvironmentNotExist do
      cfg.set_env('bar')
    end
  end


  ########################
  # MIGRATIONS_DIRECTORY #
  ########################

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

  ######################
  # CODE_DIR parameter #
  ######################

  def test_code_directory_defaults
    cfg = DBGeni::Config.new
    cfg.load("environment('foo') { }\n environment('bar') { }")
    assert_equal('code', cfg.code_dir)
  end

  def test_code_dir_settable_via_config
    cfg = DBGeni::Config.new
    cfg.load("code_directory 'other_dir'\nenvironment('foo') { }\n environment('bar') { }")
    assert_equal('other_dir', cfg.code_dir)
  end

  def test_absolution_code_dir_not_modified_windows
    cfg = DBGeni::Config.new
    cfg.base_directory = "c:\\somedir\\"
    # !! need to escape backslashes as they are escape character!
    cfg.load("code_directory 'c:\\other_dir'\nenvironment('foo') { }\n environment('bar') { }")
    assert_equal('c:\other_dir', cfg.code_dir)
  end

  def test_absolution_code_dir_not_modified_unix
    cfg = DBGeni::Config.new
    cfg.base_directory = "/somedir"
    cfg.load("code_directory '/other_dir'\nenvironment('foo') { }\n environment('bar') { }")
    assert_equal('/other_dir', cfg.code_dir)
  end

  def test_relative_code_dir_added_to_base_windows
    cfg = DBGeni::Config.new
    cfg.base_directory = "c:\\somedir\\"
    cfg.load("code_directory 'other_dir'\nenvironment('foo') { }\n environment('bar') { }")
    if Kernel.is_windows?
      assert_equal("c:\\somedir\\other_dir", cfg.code_dir)
    end
  end

  def test_relative_code_dir_added_to_base_unix
    cfg = DBGeni::Config.new
    cfg.base_directory = '/somedir'
    cfg.load("code_directory 'other_dir'\nenvironment('foo') { }\n environment('bar') { }")
    assert_equal('/somedir/other_dir', cfg.code_dir)
  end

  def test_code_dir_changes_when_base_dir_changed
    cfg = DBGeni::Config.new
    cfg.base_directory = '/somedir'
    assert_equal('/somedir/code', cfg.code_dir)
  end


  ########################
  # PLUGIN_DIRECTORY #
  ########################

  def test_plugin_directory_defaults
    cfg = DBGeni::Config.new
    cfg.load("environment('foo') { }\n environment('bar') { }")
    assert_equal(nil, cfg.plugin_directory)
  end

  def test_plugin_dir_settable_via_config
    cfg = DBGeni::Config.new
    cfg.load("plugin_directory 'other_dir'\nenvironment('foo') { }\n environment('bar') { }")
    assert_equal('other_dir', cfg.plugin_directory)
  end

  def test_absolution_plugin_dir_not_modified_windows
    cfg = DBGeni::Config.new
    cfg.base_directory = "c:\\somedir\\"
    # !! need to escape backslashes as they are escape character!
    cfg.load("plugin_directory 'c:\\other_dir'\nenvironment('foo') { }\n environment('bar') { }")
    assert_equal('c:\other_dir', cfg.plugin_directory)
  end

  def test_absolute_plugin_dir_not_modified_unix
    cfg = DBGeni::Config.new
    cfg.base_directory = "c:\\somedir\\"
    cfg.load("plugin_directory '/other_dir'\nenvironment('foo') { }\n environment('bar') { }")
    assert_equal('/other_dir', cfg.plugin_directory)
  end

  def test_relative_plugin_dir_added_to_base_windows
    cfg = DBGeni::Config.new
    cfg.base_directory = "c:\\somedir\\"
    cfg.load("plugin_directory 'other_dir'\nenvironment('foo') { }\n environment('bar') { }")
    if Kernel.is_windows?
      assert_equal("c:\\somedir\\other_dir", cfg.plugin_directory)
    end
  end

  def test_relative_plugin_dir_added_to_base_unix
    cfg = DBGeni::Config.new
    cfg.base_directory = '/somedir'
    cfg.load("plugin_directory 'other_dir'\nenvironment('foo') { }\n environment('bar') { }")
    assert_equal('/somedir/other_dir', cfg.plugin_directory)
  end

  def test_plugin_dir_changes_when_base_dir_changed
    cfg = DBGeni::Config.new
    cfg.plugin_directory 'plugins'
    cfg.base_directory = '/somedir'
    assert_equal('/somedir/plugins', cfg.plugin_directory)
  end

  ########################
  # DML_DIRECTORY #
  ########################

  def test_dml_directory_defaults
    cfg = DBGeni::Config.new
    cfg.load("environment('foo') { }\n environment('bar') { }")
    assert_equal('dml', cfg.dml_directory)
  end

  def test_dml_dir_settable_via_config
    cfg = DBGeni::Config.new
    cfg.load("dml_directory 'other_dir'\nenvironment('foo') { }\n environment('bar') { }")
    assert_equal('other_dir', cfg.dml_directory)
  end

  def test_absolution_dml_dir_not_modified_windows
    cfg = DBGeni::Config.new
    cfg.base_directory = "c:\\somedir\\"
    # !! need to escape backslashes as they are escape character!
    cfg.load("dml_directory 'c:\\other_dir'\nenvironment('foo') { }\n environment('bar') { }")
    assert_equal('c:\other_dir', cfg.dml_directory)
  end

  def test_absolute_dml_dir_not_modified_unix
    cfg = DBGeni::Config.new
    cfg.base_directory = "/somedir"
    cfg.load("dml_directory '/other_dir'\nenvironment('foo') { }\n environment('bar') { }")
    assert_equal('/other_dir', cfg.dml_directory)
  end

  def test_relative_dml_dir_added_to_base_windows
    cfg = DBGeni::Config.new
    cfg.base_directory = "c:\\somedir\\"
    cfg.load("dml_directory 'other_dir'\nenvironment('foo') { }\n environment('bar') { }")
    if Kernel.is_windows?
      assert_equal("c:\\somedir\\other_dir", cfg.dml_directory)
    end
  end

  def test_relative_dml_dir_added_to_base_unix
    cfg = DBGeni::Config.new
    cfg.base_directory = '/somedir'
    cfg.load("dml_directory 'other_dir'\nenvironment('foo') { }\n environment('bar') { }")
    assert_equal('/somedir/other_dir', cfg.dml_directory)
  end

  def test_dml_dir_changes_when_base_dir_changed
    cfg = DBGeni::Config.new
    cfg.dml_directory 'dml'
    cfg.base_directory = '/somedir'
    assert_equal('/somedir/dml', cfg.dml_directory)
  end

  #################
  # End DSL tests #
  #################

  def test_config_file_can_load_other_relative_file
    File.open("#{TestHelper::TEMP_DIR}/simple.conf", 'w') do |f|
      f.puts "database_type 'sqlite'
              include_file 'inc_config'"
    end
    File.open("#{TestHelper::TEMP_DIR}/inc_config", 'w') do |f|
      f.puts "environment('development') {
                           user     ''
                           password ''
                          database 'anything'
             }"
    end
    cfg = DBGeni::Config.load_from_file("#{TestHelper::TEMP_DIR}/simple.conf")
    assert(cfg.environments.has_key?('development'))
    assert_equal('anything', cfg.environments['development'].database)
  end




#################

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
    assert_equal('sqlite', cfg.db_type)
  end

  def test_database_type_settable_in_config
    cfg = DBGeni::Config.new
    cfg.load("database_type \"sqlite\"\nenvironment('foo') { }\n environment('bar') { }")
    assert_equal('sqlite', cfg.db_type)
  end

end
