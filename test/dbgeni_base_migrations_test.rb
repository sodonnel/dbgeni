$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$:.unshift File.expand_path(File.dirname(__FILE__))

require 'helper'
require "dbgeni"
require 'test/unit'
require 'mocha'

class TestDBGeniBaseMigrations < Test::Unit::TestCase

  include TestHelper

  def setup
    helper_clean_temp
    FileUtils.mkdir_p(File.join(TEMP_DIR, 'log'))
  end

  def teardown
    if @installer
      @installer.disconnect
    end
    DBGeni::Plugin.reset
    Mocha::Mockery.instance.stubba.unstub_all
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

  def test_bad_named_migration_does_not_apply_successfully
    @installer = DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, 'development')
    @installer.initialize_database
    migration = helper_bad_sqlite_migration
    assert_raises DBGeni::MigrationApplyFailed do
      @installer.apply_migration(migration)
    end
    assert_equal(0, @installer.applied_migrations.length)
  end

  def test_bad_named_migration_does_apply_successfully_force_on
    @installer = DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, 'development')
    @installer.initialize_database
    migration = helper_bad_sqlite_migration
    assert_nothing_raised do
      @installer.apply_migration(migration, true)
    end
    assert_equal(1, @installer.applied_migrations.length)
  end


  def test_named_migration_that_does_not_exist_errors
    @installer = DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, 'development')
    @installer.initialize_database
    migration = DBGeni::Migration.new('/dirnotexit', '201108190000_up_tst_migration.sql')
    assert_raises DBGeni::MigrationFileNotExist do
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

  def test_apply_next_bad_migration_errors
    @installer = DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, 'development')
    @installer.initialize_database
    migration = helper_bad_sqlite_migration
    assert_raises DBGeni::MigrationApplyFailed do
      @installer.apply_next_migration
    end
    assert_equal(0, @installer.applied_migrations.length)
  end

  def test_apply_next_bad_migration_force_on_no_errors
    @installer = DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, 'development')
    @installer.initialize_database
    migration = helper_bad_sqlite_migration
    assert_nothing_raised do
      @installer.apply_next_migration(true)
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

  # TODO - ideally want a couple more migrations here so that more than 1 is applied
  def test_apply_all_migrations
    @installer = DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, 'development')
    @installer.initialize_database
    migration = helper_good_sqlite_migration
    assert_nothing_raised do
      @installer.apply_all_migrations
    end
    assert_equal(1, @installer.applied_migrations.length)
  end

  # TODO - ideally want a couple more migrations here so that more than 1 is applied
  def test_apply_all_bad_migrations_force_on_no_errors
    @installer = DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, 'development')
    @installer.initialize_database
    migration = helper_bad_sqlite_migration
    assert_nothing_raised do
      @installer.apply_all_migrations(true)
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

  def test_apply_until_migration_when_migration_not_outstanding
    @installer = DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, 'development')
    @installer.initialize_database
    assert_raises DBGeni::MigrationNotOutstanding do
      @installer.apply_until_migration('201201010000::test')
    end
  end

  def test_apply_until_migration_when_one_migration
    @installer = DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, 'development')
    @installer.initialize_database
    migration = helper_good_sqlite_migration
    assert_nothing_raised do
      @installer.apply_until_migration(migration.to_s)
    end
    assert_equal('Completed', migration.status(@installer.config, @installer.connection))
  end

  def test_apply_until_migration_when_many_migrations
    @installer = DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, 'development')
    @installer.initialize_database
    # will create 4 migrations called 201108190000::test_migration upto 201108190003::test_migration
    migrations = helper_many_good_sqlite_migrations(4)
    assert_nothing_raised do
      @installer.apply_until_migration('201108190002::test_migration')
    end
    assert_equal(3, @installer.applied_migrations.length)
    assert_equal(1, @installer.outstanding_migrations.length)
    assert_equal('201108190003::test_migration', @installer.outstanding_migrations[0].to_s)
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

  def test_rollback_no_errors_for_bad_rollback_with_force_on
    @installer = DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, 'development')
    @installer.initialize_database
    migration = helper_good_sqlite_migration
    @installer.apply_migration(migration)
    migration = helper_bad_sqlite_migration
    assert_nothing_raised do
      @installer.rollback_migration(migration, true)
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

  def test_rollback_last_bad_migration_succeeds_force_on
    @installer = DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, 'development')
    @installer.initialize_database
    migration = helper_good_sqlite_migration
    @installer.apply_migration(migration)
    migration = helper_bad_sqlite_migration
    assert_nothing_raised do
      @installer.rollback_last_migration(true)
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

  def test_rollback_all_bad_migrations_succeeds_force_on
    @installer = DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, 'development')
    @installer.initialize_database
    migration = helper_good_sqlite_migration
    @installer.apply_migration(migration)
    migration = helper_bad_sqlite_migration
    assert_nothing_raised do
      @installer.rollback_all_migrations(true)
    end
    assert_equal(0, @installer.applied_migrations.length)
  end

  def test_rollback_until_migration_when_migration_not_applied
    @installer = DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, 'development')
    @installer.initialize_database
    assert_raises DBGeni::MigrationNotApplied do
      @installer.rollback_until_migration('201201010000::test')
    end
  end

  def test_rollback_until_migration_when_one_migration
    # Will not actually roll anything back, so it only goes UNTIL but not including
    @installer = DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, 'development')
    @installer.initialize_database
    migration = helper_good_sqlite_migration
    @installer.apply_all_migrations
    assert_nothing_raised do
      @installer.rollback_until_migration(migration.to_s)
    end
    assert_equal('Completed', migration.status(@installer.config, @installer.connection))
  end

  def test_rollback_until_migration_when_many_migrations
    @installer = DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, 'development')
    @installer.initialize_database
    # will create 4 migrations called 201108190000::test_migration upto 201108190003::test_migration
    migrations = helper_many_good_sqlite_migrations(4)
    @installer.apply_all_migrations
    assert_nothing_raised do
      @installer.rollback_until_migration('201108190001::test_migration')
    end
    assert_equal(2, @installer.applied_migrations.length)
    assert_equal(2, @installer.outstanding_migrations.length)
    assert_equal('201108190000::test_migration', @installer.applied_migrations[0].to_s)
  end


  ###### PLUGIN TESTS #######

  def test_migration_start_and_end_plugin_called_on_apply_migrations
    # Register a plugin for before running migrations
    pre = Class.new
    pre.class_eval do
      before_running_migrations

      def run(hook, attrs)
      end
    end

    after = Class.new
    after.class_eval do
      after_running_migrations

      def run(hook, attrs)
      end
    end

    pre.any_instance.expects(:run)
    after.any_instance.expects(:run)
    # override the load plugins method as the class above is loading them.
    DBGeni::Plugin.any_instance.stubs(:load_plugins)
    DBGeni::Config.any_instance.stubs(:plugin_directory).returns('plugins')

    @installer = DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, 'development')
    @installer.initialize_database
    migration = helper_good_sqlite_migration
    assert_nothing_raised do
      @installer.apply_all_migrations
    end
  end


  def test_migration_start_and_end_plugin_called_on_rollback_migrations
    pre = Class.new
    pre.class_eval do
      before_running_migrations

      def run(hook, attrs)
      end
    end

    after = Class.new
    after.class_eval do
      after_running_migrations

      def run(hook, attrs)
      end
    end

    pre.any_instance.expects(:run).twice
    after.any_instance.expects(:run).twice
    # override the load plugins method as the class above is loading them.
    DBGeni::Plugin.any_instance.stubs(:load_plugins)
    DBGeni::Config.any_instance.stubs(:plugin_directory).returns('plugins')

    @installer = DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, 'development')
    @installer.initialize_database
    migration = helper_good_sqlite_migration
    @installer.apply_all_migrations
    assert_nothing_raised do
      @installer.rollback_all_migrations
    end
  end

  def test_plugin_invoked_before_and_after_migration_up
    pre = Class.new
    pre.class_eval do
      before_migration_up

      def run(hook, attrs)
      end
    end

    after = Class.new
    after.class_eval do
      after_migration_up

      def run(hook, attrs)
      end
    end

    pre.any_instance.expects(:run)
    after.any_instance.expects(:run)
    # override the load plugins method as the class above is loading them.
    DBGeni::Plugin.any_instance.stubs(:load_plugins)
    DBGeni::Config.any_instance.stubs(:plugin_directory).returns('plugins')


    @installer = DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, 'development')
    @installer.initialize_database
    migration = helper_good_sqlite_migration
    @installer.apply_next_migration
  end

  def test_plugin_invoked_before_and_after_migration_down
    pre = Class.new
    pre.class_eval do
      before_migration_down

      def run(hook, attrs)
      end
    end

    after = Class.new
    after.class_eval do
      after_migration_down

      def run(hook, attrs)
      end
    end

    pre.any_instance.expects(:run)
    after.any_instance.expects(:run)
    # override the load plugins method as the class above is loading them.
    DBGeni::Plugin.any_instance.stubs(:load_plugins)
    DBGeni::Config.any_instance.stubs(:plugin_directory).returns('plugins')


    @installer = DBGeni::Base.installer_for_environment(helper_sqlite_single_environment_file, 'development')
    @installer.initialize_database
    migration = helper_good_sqlite_migration
    @installer.apply_next_migration
    @installer.rollback_last_migration
  end

end
