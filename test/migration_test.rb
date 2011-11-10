$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$:.unshift File.expand_path(File.dirname(__FILE__))

require 'helper'
require "dbgeni"
require 'test/unit'
require 'mocha'
require 'dbgeni/migrators/sqlite'


class TestMigration < Test::Unit::TestCase

  include TestHelper

  def setup
    @valid_migration = '201101011615_up_this_is_a_test_migration.sql'
    @mm = DBGeni::Migration.new('somedir', @valid_migration)
    @mm.stubs(:ensure_file_exists).returns(true) # as the file doesn't exist

    @connection = helper_sqlite_connection
    @config     = helper_sqlite_config

    FileUtils.mkdir_p(File.join(TEMP_DIR, 'log'))
    begin
      DBGeni::Initializer.initialize(@connection, @config)
    rescue DBGeni::DatabaseAlreadyInitialized
    end
    @connection.execute('delete from dbgeni_migrations')
  end

  def teardown
  end

  def test_internal_name_to_filename
    assert_equal("201101010000_up_name_of_mig.sql",
                 DBGeni::Migration.filename_from_internal_name("201101010000::name_of_mig"))
  end

  def test_filename_to_internal_name
    assert_equal("201101010000::name_of_mig",
                 DBGeni::Migration.internal_name_from_filename("201101010000_up_name_of_mig.sql"))
    assert_equal("201101010000::name_of_mig",
                 DBGeni::Migration.internal_name_from_filename("201101010000_down_name_of_mig.sql"))

  end

  def test_migration_extracted_from_milestone
    migration_name = "201101011754_up_my_migration.sql"
    File.open(File.join(TEMP_DIR, 'something.milestone'), 'w') do |f|
      f.puts migration_name
    end
    assert_equal(migration_name, DBGeni::Migration.get_milestone_migration(TEMP_DIR, 'something.milestone'))
  end

  def test_exception_raised_when_milestone_contains_junk
    migration_name = "rubbish"
    File.open(File.join(TEMP_DIR, 'something.milestone'), 'w') do |f|
      f.puts migration_name
    end
    assert_raises DBGeni::MilestoneHasNoMigration do
      DBGeni::Migration.get_milestone_migration(TEMP_DIR, 'something.milestone')
    end
  end

  def test_exception_raised_when_milestone_contains_no_migration
    File.open(File.join(TEMP_DIR, 'something.milestone'), 'w') do |f|
    end
    assert_raises DBGeni::MilestoneHasNoMigration do
      DBGeni::Migration.get_milestone_migration(TEMP_DIR, 'something.milestone')
    end
  end

  def test_invalid_filename_raises_exception
    # rubbish
    # missing part of the datestamp
    # missing up
    # missing title
    # no sql prefix
    invalid = %w(gfgffg 20110101000_up_title.sql 201101010000_title.sql 201101010000_up_.sql 201101010000_up_title)
    invalid.each do |f|
      assert_raises(DBGeni::MigrationFilenameInvalid) do
        m = DBGeni::Migration.new('anydir', f)
      end
    end
  end

  def test_rollback_file_correct
    assert_equal(@valid_migration.gsub(/up/, 'down'), @mm.rollback_file)
  end

  def test_migration_file_name_and_sequence_correct
    assert_equal(@valid_migration, @mm.migration_file)
    assert_equal('this_is_a_test_migration', @mm.name)
    assert_equal('201101011615', @mm.sequence)
  end


  ##########
  # ==     #
  ##########

  def test_same_migration_file_is_equal
    m1 = DBGeni::Migration.new('anydir', @valid_migration)
    m2 = DBGeni::Migration.new('anydir', @valid_migration)
    assert_equal(m1, m2)
  end

  def test_different_migration_file_is_not_equal
    m1 = DBGeni::Migration.new('anydir', @valid_migration)
    m2 = DBGeni::Migration.new('anydir', "201201010000_up_migration.sql")
    assert_not_equal(m1, m2)
  end

  def test_same_migration_different_directory_is_not_equal
    m1 = DBGeni::Migration.new('anydir',  @valid_migration)
    m2 = DBGeni::Migration.new('anydir2', @valid_migration)
    assert_not_equal(m1, m2)
  end



  #####################################################
  # set_* (pending, failed, rolledback, completed etc #
  #####################################################

  def test_insert_pending_details_for_migration
    @mm.set_pending(@config, @connection)
    assert_equal('Pending', get_state(@mm))
  end

  def test_insert_failed_details_for_migration
    @mm.set_failed(@config, @connection)
    assert_equal('Failed', get_state(@mm))
  end

  def test_insert_rolledback_details_for_migration
    @mm.set_rolledback(@config, @connection)
    assert_equal('Rolledback', get_state(@mm))
  end

  def test_insert_completed_details_for_migration
    @mm.set_completed(@config, @connection)
    assert_equal('Completed', get_state(@mm))
  end

  def test_update_details_from_pending_to_complete_for_migration
    @mm.set_pending(@config, @connection)
    @mm.set_completed(@config, @connection)
    assert_equal('Completed', get_state(@mm))
  end

  def test_get_migration_state
    assert_equal('New', @mm.status(@config, @connection))
    @mm.set_pending(@config, @connection)
    assert_equal('Pending', @mm.status(@config, @connection))
    @mm.set_failed(@config, @connection)
    assert_equal('Failed', @mm.status(@config, @connection))
    @mm.set_completed(@config, @connection)
    assert_equal('Completed', @mm.status(@config, @connection))
    @mm.set_rolledback(@config, @connection)
    assert_equal('Rolledback', @mm.status(@config, @connection))
  end


  ############
  # applied? #
  ############

  def test_not_applied_migration_is_not_applied
    assert_equal(false, @mm.applied?(@config, @connection))
  end

  # TODO - stub set calls?
  def test_pending_migration_is_not_applied
    @mm.set_pending(@config, @connection)
    assert_equal(false, @mm.applied?(@config, @connection))
  end

  def test_completed_migration_is_applied
    @mm.set_completed(@config, @connection)
    assert_equal(true, @mm.applied?(@config, @connection))
  end

  #############
  # apply!   #
  #############

  def test_apply_good_migration
    DBGeni::Migrator::Sqlite.any_instance.stubs(:apply).with(@mm, nil)
    assert_nothing_raised do
     @mm.apply!(@config, @connection)
    end
    assert_equal('Completed', @mm.status(@config, @connection))
  end

  def test_apply_good_migration_force_on
    DBGeni::Migrator::Sqlite.any_instance.stubs(:apply).with(@mm, true)
    assert_nothing_raised do
     @mm.apply!(@config, @connection, true)
    end
    assert_equal('Completed', @mm.status(@config, @connection))
  end

  def test_apply_already_applied_migration_errors
    DBGeni::Migrator::Sqlite.any_instance.stubs(:apply).with(@mm, nil)
    assert_nothing_raised do
      @mm.apply!(@config, @connection)
    end
    assert_raises DBGeni::MigrationAlreadyApplied do
      @mm.apply!(@config, @connection)
    end
  end

  def test_apply_migration_with_errors
    DBGeni::Migrator::Sqlite.any_instance.stubs(:apply).with(@mm, nil).raises(DBGeni::MigrationContainsErrors)

    assert_raises DBGeni::MigrationApplyFailed do
      @mm.apply!(@config, @connection)
    end
    assert_equal(false, @mm.applied?(@config, @connection))
    assert_equal('Failed', @mm.status(@config, @connection))
    DBGeni::Migrator::Sqlite.unstub(:apply)
  end

  def test_apply_migration_with_errors_force_on
    DBGeni::Migrator::Sqlite.any_instance.stubs(:apply).with(@mm, true)

    assert_nothing_raised do
      @mm.apply!(@config, @connection, true)
    end
    assert_equal(true, @mm.applied?(@config, @connection))
    assert_equal('Completed', @mm.status(@config, @connection))
  end


  #############
  # rollback! #
  #############

  def test_not_applied_migration_will_not_rollback
    DBGeni::Migrator::Sqlite.any_instance.stubs(:rollback).with(@mm, nil)

    assert_raises DBGeni::MigrationNotApplied do
      @mm.rollback!(@config, @connection)
    end

    # if a migration is partly applied, then it will still rollback, eg if it is PENDING etc
    @mm.set_pending(@config, @connection)
    assert_nothing_raised do
      @mm.rollback!(@config, @connection)
      assert_equal('Rolledback', @mm.status(@config, @connection))
    end
    @mm.set_failed(@config, @connection)
    assert_nothing_raised do
      @mm.rollback!(@config, @connection)
      assert_equal('Rolledback', @mm.status(@config, @connection))
    end
    @mm.set_completed(@config, @connection)
    assert_nothing_raised do
      @mm.rollback!(@config, @connection)
      assert_equal('Rolledback', @mm.status(@config, @connection))
    end
    @mm.set_rolledback(@config, @connection)
    assert_raises DBGeni::MigrationNotApplied do
      @mm.rollback!(@config, @connection)
    end
  end


  def test_apply_rollback_with_errors_raises_exception
    DBGeni::Migrator::Sqlite.any_instance.stubs(:rollback).with(@mm, nil).raises(DBGeni::MigrationContainsErrors)
    @mm.set_completed(@config, @connection)
    assert_raises DBGeni::MigrationApplyFailed do
      @mm.rollback!(@config, @connection)
    end
  end

  def test_apply_rollback_with_errors_and_force_on_raises_no_exception
    DBGeni::Migrator::Sqlite.any_instance.expects(:rollback).with(@mm, true)
    @mm.set_completed(@config, @connection)

    assert_nothing_raised do
     @mm.rollback!(@config, @connection, true)
    end
    assert_equal(false, @mm.applied?(@config, @connection))
    assert_equal('Rolledback', @mm.status(@config, @connection))
  end

  def test_logfile_available_on_apply
    DBGeni::Migrator::Sqlite.any_instance.expects(:apply).with(@mm, nil)
    DBGeni::Migrator::Sqlite.any_instance.expects(:logfile).returns('somelog.log')
    assert_nothing_raised do
      @mm.apply!(@config, @connection)
    end
    assert_equal('somelog.log', @mm.logfile)
  end

  def test_logfile_available_on_apply_bad_migration
    DBGeni::Migrator::Sqlite.any_instance.expects(:apply).with(@mm, nil).raises(DBGeni::MigrationContainsErrors)
    DBGeni::Migrator::Sqlite.any_instance.expects(:logfile).returns('somelog.log')

    assert_raises DBGeni::MigrationApplyFailed do
      @mm.apply!(@config, @connection)
    end
    assert_equal('somelog.log', @mm.logfile)
  end

  def test_logfile_available_on_rollback
    DBGeni::Migrator::Sqlite.any_instance.expects(:rollback).with(@mm, nil)
    DBGeni::Migrator::Sqlite.any_instance.expects(:logfile).returns('somelog.log')
    @mm.set_completed(@config, @connection)
    assert_nothing_raised do
      @mm.rollback!(@config, @connection)
    end
    assert_equal('somelog.log', @mm.logfile)
  end

  def test_logfile_available_on_rollback_bad_migration
    DBGeni::Migrator::Sqlite.any_instance.expects(:rollback).with(@mm, nil).raises(DBGeni::MigrationContainsErrors)
    DBGeni::Migrator::Sqlite.any_instance.expects(:logfile).returns('somelog.log')
    @mm.set_completed(@config, @connection)
    assert_raises DBGeni::MigrationApplyFailed do
      @mm.rollback!(@config, @connection)
    end
    assert_equal('somelog.log', @mm.logfile)
  end

  private

  def get_state(m)
    results = @connection.execute("select migration_state
                                   from #{@config.db_table}
                                   where sequence_or_hash = :seq
                                   and   migration_name   = :migration", m.sequence, m.name)
    if results.length == 1
      results[0][0]
    else
      nil
    end
  end
end
