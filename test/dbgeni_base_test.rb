$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$:.unshift File.expand_path(File.dirname(__FILE__))

require 'helper'
require "dbgeni"
require 'test/unit'

class TestDBGeniBase < Test::Unit::TestCase

  include TestHelper

  def setup
    helper_clean_temp
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

  ###################
  # Migrations      #
  ###################

  def test_can_list_migrations_when_none_exist
    @installer = DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, 'development')
    assert_equal(0, @installer.migrations.length)
  end

  def test_can_list_migrations_when_some_exist
    @installer = DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, 'development')
    helper_good_sqlite_migration
    assert_equal(1, @installer.migrations.length)
  end

  def test_correct_error_raised_when_migration_directory_not_exist
    @installer = DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, 'development')
    @installer.config.migrations_directory 'not_there'
    assert_raises DBGeni::MigrationDirectoryNotExist do
      @installer.migrations
    end
  end



  ##########################
  # Outstanding Migrations #
  ##########################

  def test_can_list_outstanding_migrations_when_none_exist
    @installer = DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, 'development')
    @installer.initialize_database
    assert_equal(0, @installer.outstanding_migrations.length)
  end

  def test_can_list_outstanding_migrations_when_some_exist
    @installer = DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, 'development')
    @installer.initialize_database
    helper_good_sqlite_migration
    assert_equal(1, @installer.outstanding_migrations.length)
  end

  def test_can_list_outstanding_migrations_when_all_applied
    @installer = DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, 'development')
    @installer.initialize_database
    helper_good_sqlite_migration
    @installer.apply_all_migrations
    assert_equal(0, @installer.outstanding_migrations.length)
  end

  def test_correct_error_raised_when_outstanding_migrations_on_not_initialized_db
    @installer = DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, 'development')
    helper_good_sqlite_migration
    assert_raises DBGeni::DatabaseNotInitialized do
      @installer.outstanding_migrations
    end
  end

  ######################
  # Applied Migrations #
  ######################

  def test_can_list_applied_migrations_when_none_exist
    @installer = DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, 'development')
    @installer.initialize_database
    assert_equal(0, @installer.applied_migrations.length)
  end

  def test_can_list_applied_migrations_when_some_exist
    @installer = DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, 'development')
    @installer.initialize_database
    helper_good_sqlite_migration
    @installer.apply_next_migration
    assert_equal(1, @installer.applied_migrations.length)
  end

  def test_can_list_applied_migrations_when_none_applied
    @installer = DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, 'development')
    @installer.initialize_database
    helper_good_sqlite_migration
    assert_equal(0, @installer.applied_migrations.length)
  end

  def test_correct_error_raised_when_applied_migrations_on_not_initialized_db
    @installer = DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, 'development')
    helper_good_sqlite_migration
    assert_raises DBGeni::DatabaseNotInitialized do
      @installer.applied_migrations
    end
  end

  #######################
  # Applying Migrations #
  #######################

  def test_good_named_migration_applies_successfully
    @installer = DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, 'development')
    @installer.initialize_database
    migration = helper_good_sqlite_migration
    assert_nothing_raised do
      @installer.apply_migration(migration)
    end
    assert_equal(1, @installer.applied_migrations.length)
  end

  def test_bad_named_migration_applies_successfully
    @installer = DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, 'development')
    @installer.initialize_database
    migration = helper_bad_sqlite_migration
    assert_raises DBGeni::MigrationApplyFailed do
      @installer.apply_migration(migration)
    end
    assert_equal(0, @installer.applied_migrations.length)
  end

  def test_named_migration_that_does_not_exist_errors
    @installer = DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, 'development')
    @installer.initialize_database
    migration = DBGeni::Migration.new('/dirnotexit', '201108190000_up_tst_migration.sql')
    assert_raises DBGeni::MigrationApplyFailed do
      @installer.apply_migration(migration)
    end
    assert_equal(0, @installer.applied_migrations.length)
  end

  def test_apply_next_good_migration
    @installer = DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, 'development')
    @installer.initialize_database
    migration = helper_good_sqlite_migration
    assert_nothing_raised do
      @installer.apply_next_migration
    end
    assert_equal(1, @installer.applied_migrations.length)
  end

  def test_apply_next_good_migration_when_none_exist
    @installer = DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, 'development')
    @installer.initialize_database
    assert_raises DBGeni::NoOutstandingMigrations do
      @installer.apply_next_migration
    end
    assert_equal(0, @installer.applied_migrations.length)
  end

  # ideally want a couple more migrations here so that more than 1 is applied
  def test_apply_all_migrations
    @installer = DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, 'development')
    @installer.initialize_database
    migration = helper_good_sqlite_migration
    assert_nothing_raised do
      @installer.apply_all_migrations
    end
    assert_equal(1, @installer.applied_migrations.length)
  end

  def test_apply_all_migrations_when_none_outstanding
    @installer = DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, 'development')
    @installer.initialize_database
    assert_raises DBGeni::NoOutstandingMigrations do
      @installer.apply_all_migrations
    end
    assert_equal(0, @installer.applied_migrations.length)
  end

  ##########################
  # Applying Rollbacks etc #
  ##########################

  def test_rollback_fails_when_not_yet_applied
    @installer = DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, 'development')
    @installer.initialize_database
    migration = helper_good_sqlite_migration
    assert_raises DBGeni::MigrationNotApplied do
      @installer.rollback_migration(migration)
    end
  end

  def test_rollback_succeeds_for_good_rollback
    @installer = DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, 'development')
    @installer.initialize_database
    migration = helper_good_sqlite_migration
    @installer.apply_migration(migration)
    assert_nothing_raised do
      @installer.rollback_migration(migration)
    end
    assert_equal(0, @installer.applied_migrations.length)
  end

  def test_rollback_errors_for_bad_rollback
    @installer = DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, 'development')
    @installer.initialize_database
    migration = helper_good_sqlite_migration
    @installer.apply_migration(migration)
    migration = helper_bad_sqlite_migration
    assert_raises DBGeni::MigrationApplyFailed do
      @installer.rollback_migration(migration)
    end
    assert_equal(0, @installer.applied_migrations.length)
  end

  def test_rollback_last_migration_succeeds
    @installer = DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, 'development')
    @installer.initialize_database
    migration = helper_good_sqlite_migration
    @installer.apply_migration(migration)
    assert_nothing_raised do
      @installer.rollback_last_migration
    end
    assert_equal(0, @installer.applied_migrations.length)
  end

  def test_rollback_all_migrations_succeeds
    @installer = DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, 'development')
    @installer.initialize_database
    migration = helper_good_sqlite_migration
    @installer.apply_migration(migration)
    assert_nothing_raised do
      @installer.rollback_all_migrations
    end
    assert_equal(0, @installer.applied_migrations.length)
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

