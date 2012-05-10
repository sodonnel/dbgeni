$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))

require "dbgeni"
require 'test/unit'

class TestEnvironment < Test::Unit::TestCase

  def setup
  end

  def teardown
  end

  def test_is_loadable_by_default
    env = DBGeni::Environment.new('test_env')
    assert_equal(true, env.__is_loadable?)
  end

  def test_set_not_loadable
    env = DBGeni::Environment.new('test_env')
    env.__completed_loading
    assert_equal(false, env.__is_loadable?)
  end

  def test_set_loadable
    env = DBGeni::Environment.new('test_env')
    env.__completed_loading
    assert_equal(false, env.__is_loadable?)
    env.__enable_loading
    assert_equal(true, env.__is_loadable?)
  end

  def test_parameter_loaded
    env = DBGeni::Environment.new('test_env')
    env.param('foo')
    env.__completed_loading
    assert_equal('foo', env.param)
  end

  def test_duplicate_parameter_loaded
    env = DBGeni::Environment.new('test_env')
    env.param('foo')
    env.param('bar')
    env.__completed_loading
    assert_equal('bar', env.param)
  end

  def test_param_with_equals_sign
    env = DBGeni::Environment.new('test_env')
    env.param = 'foo'
    env.__completed_loading
    assert_equal('foo', env.param)
  end

  def test_unloaded_params_returns_nil
    env = DBGeni::Environment.new('test_env')
    env.param = 'foo'
    env.__completed_loading
    assert_equal(nil, env.non_existent)
  end

  def test_defaults_merged_successfully
    env = DBGeni::Environment.new('test_env')
    defaults = {
      'param2' => 'bar'
    }
    env.param = 'foo'
    env.__merge_defaults(defaults)
    env.__completed_loading
    assert_equal('foo', env.param)
    assert_equal('bar', env.param2)
  end

  def test_defaults_merged_but_env_param_overrides
    env = DBGeni::Environment.new('test_env')
    defaults = {
      'param2' => 'bar',
      'param'  => 'biggles'
    }
    env.param = 'foo'
    env.__merge_defaults(defaults)
    env.__completed_loading
    assert_equal('foo', env.param)
    assert_equal('bar', env.param2)
  end

  def test_errors_if_param_has_no_value
    env = DBGeni::Environment.new('test_env')
    env.param
    env.__completed_loading
    assert_equal(nil, env.param)
  end

  def test_environment_can_be_merged_with_another
    env  = DBGeni::Environment.new('test_env')
    env2 = DBGeni::Environment.new('test_env')
    env.param   = 'foo'
    env.param2  = 'foobar'
    env2.merged = 'original'
    env2.param  = 'overide'
    env.__completed_loading
    env2.__completed_loading

    env.__merge_environment(env2)

    assert_equal('overide', env.param)
    assert_equal('foobar'  , env.param2)
    assert_equal('original'  , env.merged)
  end


end
