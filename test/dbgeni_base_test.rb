$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$:.unshift File.expand_path(File.dirname(__FILE__))

require 'helper'
require "dbgeni"
require 'test/unit'

class TestDBGeniBase < Test::Unit::TestCase

  include TestHelper

  def setup
    helper_clean_temp
    FileUtils.mkdir_p(File.join(TEMP_DIR, 'log'))
  end

  def teardown
    if @installer
      @installer.disconnect
    end
  end

  # all tests against SQLITE, other databases are tested in lower level tests.

  #############################
  # Installer for environment #
  #############################

  def test_can_initialize_with_single_environment
    assert_nothing_raised do
      DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, 'development')
    end
  end

  def test_can_initialize_with_single_non_specified_environment
    assert_nothing_raised do
      DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, nil)
    end
  end

  def test_can_initialize_with_multiple_environment
    assert_nothing_raised do
      DBGeni::Base.installer_for_environment(helper_sqlite_multiple_environment_file, 'development')
    end
  end

  def test_correct_error_when_no_environment_specified
    assert_raises DBGeni::ConfigAmbiguousEnvironment do
      DBGeni::Base.installer_for_environment(helper_sqlite_multiple_environment_file, nil)
    end
  end

  def test_correct_error_when_environment_specified_does_not_exist
    assert_raises DBGeni::EnvironmentNotExist do
      DBGeni::Base.installer_for_environment(helper_sqlite_multiple_environment_file, 'not_exist')
    end
  end


  def test_correct_error_when_config_file_does_not_exist
    assert_raises DBGeni::ConfigFileNotExist do
      DBGeni::Base.installer_for_environment("non_exist_config", nil)
    end
  end

  def test_correct_error_when_no_config_file_supplied
    assert_raises DBGeni::ConfigFileNotSpecified do
      DBGeni::Base.installer_for_environment(nil, nil)
    end
  end

  ##############################
  # Select and get environment #
  ##############################

  def test_environment_can_be_selected_and_changed
    @installer = DBGeni::Base.new(helper_sqlite_multiple_environment_file)
    assert_nothing_raised do
      @installer.select_environment('development')
    end
    assert_equal('development', @installer.selected_environment_name)
    assert_nothing_raised do
      @installer.select_environment('test')
    end
    assert_equal('test', @installer.selected_environment_name)
  end

  def test_default_environment_selected_when_only_one
    @installer = DBGeni::Base.new(helper_sqlite_single_environment_file)
    assert_equal('development', @installer.selected_environment_name)
  end

  def test_environment_can_be_selected_when_only_one
    @installer = DBGeni::Base.new(helper_sqlite_single_environment_file)
    assert_nothing_raised do
      @installer.select_environment('development')
    end
    assert_equal('development', @installer.selected_environment_name)
  end

  def test_nil_returned_when_no_environment_selected
    @installer = DBGeni::Base.new(helper_sqlite_multiple_environment_file)
    assert_equal(nil, @installer.selected_environment_name)
  end

  def test_correct_error_raised_when_environment_does_not_exist_selected
    @installer = DBGeni::Base.new(helper_sqlite_multiple_environment_file)
    assert_raises DBGeni::EnvironmentNotExist do
      @installer.select_environment 'not_exist'
    end
  end


  #######################
  # Initialize_Database #
  #######################

  def test_non_initialized_db_can_be_initialized
    @installer = DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, 'development')
    assert_nothing_raised do
      @installer.initialize_database
    end
  end

  def test_already_initialized_db_raises_error_when_initialized
    @installer = DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, 'development')
    @installer.initialize_database
    assert_raises DBGeni::DatabaseAlreadyInitialized do
      @installer.initialize_database
    end
  end

end

