$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$:.unshift File.expand_path(File.dirname(__FILE__))

# require 'helper'
require "dbgeni"
require 'test/unit'
require 'mocha'

class TestHook < Test::Unit::TestCase

#  include TestHelper

  def setup
  end

  def teardown
    DBGeni::Plugin.reset
    Mocha::Mockery.instance.stubba.unstub_all
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

  def test_error_on_run_invalid_hook
    assert_raises DBGeni::InvalidHook do
      p = DBGeni::Plugin.new
      p.run_plugins(:not_exist, {})
    end
  end

  def test_load_plugins
    Dir.stubs(:entries).returns(['p1.rb', 'p2.rb', '.', '..', 'p3.txt'])
    p = DBGeni::Plugin.new
    p.expects(:load_plugin).with '/somedir/p1.rb'
    p.expects(:load_plugin).with '/somedir/p2.rb'
    p.load_plugins('/somedir')
  end

  def test_load_plugins_invalid_directory_raises_exception
    p = DBGeni::Plugin.new
    # directory doesn't exist
    assert_raises DBGeni::PluginDirectoryNotAccessible do
      p.load_plugins('/dir/not/exist')
    end
    # permission denied
    assert_raises DBGeni::PluginDirectoryNotAccessible do
      p.load_plugins('/root')
    end
  end

  # Run Plugins
  def test_run_plugins_when_no_plugins
    p = DBGeni::Plugin.new
    assert_nothing_raised do
      p.run_plugins(:before_migration_up, { })
    end
  end

  def test_run_plugins_with_invalid_hook_raises_exception
    p = DBGeni::Plugin.new
    assert_raises DBGeni::InvalidHook do
      p.run_plugins(:bad_hook, { })
    end
  end

  def test_run_plugins_plugin_called_when_run
    klass = Class.new
    klass.class_eval do
      before_migration_up

      def run(hook, attrs)
      end
    end
    klass.any_instance.expects(:run)

    p = DBGeni::Plugin.new
    p.run_plugins(:before_migration_up, { })
  end


  # Run Plugin
  def test_run_plugin_error_if_plugin_does_not_respond_to_run
    klass = Class.new
    p = DBGeni::Plugin.new
    assert_raises DBGeni::PluginDoesNotRespondToRun do
      p.run_plugin(klass, :before_migration_up, {})
    end
  end

  def test_run_plugin_successfully_executes_plugin
    klass = Class.new
    klass.class_eval do
      def run(hook, attrs)
      end
    end
    klass.any_instance.expects(:run)

    p = DBGeni::Plugin.new
    p.run_plugin(klass, :before_migration_up, {})
  end


  def test_loading_class_with_plugin_hook_registers_plugin
    klass = Class.new
    klass.class_eval do
      before_migration_up

      def run(hook, attrs)
      end
    end
    assert_equal(klass, DBGeni::Plugin.hooks[:before_migration_up].first)
  end

  def test_loading_class_with_multiple_plugin_hook_registers_plugin_multiple_times
    klass = Class.new
    klass.class_eval do
      before_migration_up
      after_migration_up

      def run(hook, attrs)
      end
    end
    assert_equal(klass, DBGeni::Plugin.hooks[:before_migration_up].first)
    assert_equal(klass, DBGeni::Plugin.hooks[:after_migration_up].first)
  end

  ## TODO test actual load_plugin method, which will actually require a file

end
