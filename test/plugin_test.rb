$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$:.unshift File.expand_path(File.dirname(__FILE__))

# require 'helper'
require "dbgeni"
require 'test/unit'

class TestHook < Test::Unit::TestCase

#  include TestHelper

  def setup
  end

  def teardown
    DBGeni::Plugin.reset
  end

  def test_can_access_hooks
    assert(DBGeni::Plugin.hooks.is_a? Hash)
  end

  def test_error_on_install_invalid_hook
    assert_raises DBGeni::InvalidHook do
      DBGeni::Plugin.install_plugin(:not_exist, Array)
    end
  end

  def test_class_installed_as_plugin
    assert_nothing_raised do
      DBGeni::Plugin.install_plugin(:before_migration_up, Array)
    end
    assert_equal(Array, DBGeni::Plugin.hooks[:before_migration_up].first)
  end

  def test_plugins_can_be_cleared
    assert_nothing_raised do
      DBGeni::Plugin.install_plugin(:before_migration_up, Array)
      DBGeni::Plugin.reset
    end
    assert_equal(0, DBGeni::Plugin.hooks[:before_migration_up].length)
  end

  def test_run_plugin_error_if_plugin_does_not_respond_to_run
    klass = Class.new
    p = DBGeni::Plugin.new
    assert_raises DBGeni::PluginDoesNotRespondToRun do
      p.run_plugin(klass, {})
    end
  end

  def test_run_plugin_successfully_executes_plugin
    klass = Class.new
    klass.class_eval do
      def run(attrs)
      end
    end

    p = DBGeni::Plugin.new
    assert_nothing_raised do
      p.run_plugin(klass, {})
    end
  end

  def test_error_on_run_invalid_hook
    assert_raises DBGeni::InvalidHook do
      p = DBGeni::Plugin.new
      p.run_plugins(:not_exist, {})
    end
  end

  # Load plugins
  # Run Plugins

  def test_loading_class_with_plugin_hook_registers_plugin
    klass = Class.new
    klass.class_eval do
      before_migration_up

      def run(attrs)
      end
    end
    assert_equal(klass, DBGeni::Plugin.hooks[:before_migration_up].first)
  end

  def test_loading_class_with_multiple_plugin_hook_registers_plugin_multiple_times
    klass = Class.new
    klass.class_eval do
      before_migration_up
      after_migration_up

      def run(attrs)
      end
    end
    assert_equal(klass, DBGeni::Plugin.hooks[:before_migration_up].first)
    assert_equal(klass, DBGeni::Plugin.hooks[:after_migration_up].first)
  end

end
