$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$:.unshift File.expand_path(File.dirname(__FILE__))

require 'helper'
require "dbgeni"
require 'test/unit'
require 'mocha'


class TestDBGeniBaseProcOracle < Test::Unit::TestCase

  include TestHelper

  def setup
    # clear down and recreate the working directories.
    @code_directory = File.expand_path(File.join(File.dirname(__FILE__), "..", "temp", "code"))
    FileUtils.rm_rf(@code_directory)
    FileUtils.mkdir_p(@code_directory)
    # 5 valid code files and one non code file
    %w(p1.prc p2.pks p3.pkb p4.fnc p5.trg p6.abc).each do |f|
      File.open(File.join(@code_directory, f), 'w') do |fh|
        fh.puts "create or replace procedure proc1\nas\nbegin\n  null;\nend;"
      end
    end

    # clean out the database so it looks like nothing is installed
    @@connection ||= helper_oracle_connection
    @connection = @@connection
    @config     = helper_oracle_config
    @installer = DBGeni::Base.installer_for_environment(helper_oracle_single_environment_file, 'development')
    begin
      @installer.initialize_database
    rescue DBGeni::DatabaseAlreadyInitialized
    end
    @connection.execute("delete from #{@config.db_table}")
    begin
      @connection.execute("drop procedure proc1")
    rescue Exception => e
    end
  end


  def teardown
  end

  #######################
  # Code - listing etc  #
  #######################

  def test_can_list_code_modules_when_none_exist
    clean_code_files
    assert_equal(0, @installer.code.length)
  end

  def test_can_list_code_modules_when_some_exist
    assert_equal(5, @installer.code.length)
  end

  def test_correct_error_raised_when_code_directory_not_exist
    @installer.config.code_directory 'not_there'
    assert_raises DBGeni::CodeDirectoryNotExist do
      @installer.code
    end
  end

  ##### Current Procs
  def test_current_code_modules_listed
    assert_equal(0, @installer.current_code.length)
    @installer.apply_code(@installer.outstanding_code[0])
    assert_equal(1, @installer.current_code.length)
  end

  ##### Outstanding Procs
  def test_outstanding_code_modules_listed
    assert_equal(5, @installer.outstanding_code.length)
    @installer.apply_code(@installer.outstanding_code[0])
    assert_equal(4, @installer.outstanding_code.length)
  end

  ###################
  # Code - applying #
  ###################

  def test_apply_single_procedure
    # The apply_code method expect a 'code' object to be passed in.
    code_obj = @installer.outstanding_code.first
    assert_nothing_raised do
      @installer.apply_code(code_obj)
    end
    assert_equal(true, code_obj.current?(@config, @connection))
  end

  def test_apply_outstanding_code
    assert_nothing_raised do
      @installer.apply_outstanding_code
    end
    assert_equal(0, @installer.outstanding_code.length)
  end

  def test_apply_all_code
    assert_nothing_raised do
      @installer.apply_all_code
    end
    assert_equal(0, @installer.outstanding_code.length)
  end

  def test_apply_all_code_does_not_raise_when_no_code_outstanding
    assert_nothing_raised do
      @installer.apply_all_code
    end
    assert_equal(0, @installer.outstanding_code.length)
    assert_nothing_raised do
      @installer.apply_all_code
    end
  end

  def test_apply_outstanding_code_raises_when_no_code_outstanding
    assert_nothing_raised do
      @installer.apply_outstanding_code
    end
    assert_equal(0, @installer.outstanding_code.length)
    assert_raises DBGeni::NoOutstandingCode do
      @installer.apply_outstanding_code
    end
  end

  ###################
  # Code - removing #
  ###################

  def test_remove_single_procedure_which_is_not_installed
    code_obj = @installer.outstanding_code.first
    assert_nothing_raised do
      @installer.remove_code(code_obj)
    end
  end

  def test_remove_single_procedure_which_is_installed
    code_obj = @installer.outstanding_code.first
    code_obj.apply!(@config, @connection)
    assert_nothing_raised do
      @installer.remove_code(code_obj)
    end
    assert_equal(5, @installer.outstanding_code.length)
  end

  def test_remove_single_procedure_which_does_not_exist_raises
    code_obj = DBGeni::Code.new(@config.code_dir, 'someproc.prc')
    assert_raises DBGeni::CodeFileNotExist do
      @installer.remove_code(code_obj)
    end
  end

  def test_remove_all_code_when_none_installed
    assert_nothing_raised do
      @installer.remove_all_code
    end
    assert_equal(5, @installer.outstanding_code.length)
  end

  def test_remove_all_code_when_installed
    assert_nothing_raised do
      @installer.apply_all_code
      assert_equal(0, @installer.outstanding_code.length)
      @installer.remove_all_code
    end
    assert_equal(5, @installer.outstanding_code.length)
  end

  ######### PLUGINS ##########

  def test_code_start_and_end_plugins_invoked_applying_code
    pre = Class.new
    pre.class_eval do
      before_modifying_code

      def run(hook, attrs)
      end
    end

    after = Class.new
    after.class_eval do
      after_modifying_code

      def run(hook, attrs)
      end
    end

    pre.any_instance.expects(:run).twice
    after.any_instance.expects(:run).twice
    # override the load plugins method as the class above is loading them.
    DBGeni::Plugin.any_instance.stubs(:load_plugins)
    DBGeni::Config.any_instance.stubs(:plugin_directory).returns('plugins')


    assert_nothing_raised do
      @installer.apply_all_code
      @installer.remove_all_code
    end
  end

  def test_code_start_and_end_plugins_invoked_applying_and_removing_code
    pre = Class.new
    pre.class_eval do
      before_modifying_code

      def run(hook, attrs)
      end
    end

    after = Class.new
    after.class_eval do
      after_modifying_code

      def run(hook, attrs)
      end
    end

    pre.any_instance.expects(:run).twice
    after.any_instance.expects(:run).twice
    # override the load plugins method as the class above is loading them.
    DBGeni::Plugin.any_instance.stubs(:load_plugins)
    DBGeni::Config.any_instance.stubs(:plugin_directory).returns('plugins')


    assert_nothing_raised do
      @installer.apply_all_code
      @installer.remove_all_code
    end
  end

  def test_plugins_fired_before_and_after_code_apply
    pre = Class.new
    pre.class_eval do
      before_code_apply

      def run(hook, attrs)
      end
    end

    after = Class.new
    after.class_eval do
      after_code_apply

      def run(hook, attrs)
      end
    end

    pre.any_instance.expects(:run)
    after.any_instance.expects(:run)
    # override the load plugins method as the class above is loading them.
    DBGeni::Plugin.any_instance.stubs(:load_plugins)
    DBGeni::Config.any_instance.stubs(:plugin_directory).returns('plugins')

    @installer.apply_list_of_code(['p1.prc'])
  end

  def test_plugins_fired_before_and_after_code_remove
    pre = Class.new
    pre.class_eval do
      before_code_remove

      def run(hook, attrs)
      end
    end

    after = Class.new
    after.class_eval do
      after_code_remove

      def run(hook, attrs)
      end
    end

    pre.any_instance.expects(:run)
    after.any_instance.expects(:run)
    # override the load plugins method as the class above is loading them.
    DBGeni::Plugin.any_instance.stubs(:load_plugins)
    DBGeni::Config.any_instance.stubs(:plugin_directory).returns('plugins')

    @installer.apply_list_of_code(['p1.prc'])
    @installer.remove_list_of_code(['p1.prc'])
  end

  private

  def clean_code_files
    FileUtils.rm_rf(File.join(TestHelper::TEMP_DIR, 'code'))
    FileUtils.mkdir_p(@code_directory)
  end


end
