$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$:.unshift File.expand_path(File.dirname(__FILE__))

require 'helper'
require "dbgeni"
require 'test/unit'

class TestMigration < Test::Unit::TestCase

  include TestHelper

  def setup
    @valid_migration = '201101011615_up_this_is_a_test_migration.sql'

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



  def test_valid_filename_ok
    m = DBGeni::Migration.new('anydir', @valid_migration)
    assert_equal('this_is_a_test_migration', m.name)
    assert_equal('201101011615', m.sequence)
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
    m = DBGeni::Migration.new('anydir', @valid_migration)
    assert_equal(@valid_migration.gsub(/up/, 'down'), m.rollback_file)
  end

  def test_migration_file_correct
    m = DBGeni::Migration.new('anydir', @valid_migration)
    assert_equal(@valid_migration, m.migration_file)
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
    m = DBGeni::Migration.new('anydir', @valid_migration)
    m.set_pending(@config, @connection)
    assert_equal('Pending', get_state(m))
  end

  def test_insert_failed_details_for_migration
    m = DBGeni::Migration.new('anydir', @valid_migration)
    m.set_failed(@config, @connection)
    assert_equal('Failed', get_state(m))
  end

  def test_insert_rolledback_details_for_migration
    m = DBGeni::Migration.new('anydir', @valid_migration)
    m.set_rolledback(@config, @connection)
    assert_equal('Rolledback', get_state(m))
  end

  def test_insert_completed_details_for_migration
    m = DBGeni::Migration.new('anydir', @valid_migration)
    m.set_completed(@config, @connection)
    assert_equal('Completed', get_state(m))
  end

  def test_update_details_from_pending_to_complete_for_migration
    m = DBGeni::Migration.new('anydir', @valid_migration)
    m.set_pending(@config, @connection)
    m.set_completed(@config, @connection)
    assert_equal('Completed', get_state(m))
  end

  def test_get_migration_state
    m = DBGeni::Migration.new('anydir', @valid_migration)
    assert_equal('New', m.status(@config, @connection))
    m.set_pending(@config, @connection)
    assert_equal('Pending', m.status(@config, @connection))
    m.set_failed(@config, @connection)
    assert_equal('Failed', m.status(@config, @connection))
    m.set_completed(@config, @connection)
    assert_equal('Completed', m.status(@config, @connection))
    m.set_rolledback(@config, @connection)
    assert_equal('Rolledback', m.status(@config, @connection))
  end


  ############
  # applied? #
  ############

  def test_not_applied_migration_is_not_applied
    m = DBGeni::Migration.new('anydir', @valid_migration)
    assert_equal(false, m.applied?(@config, @connection))
  end

  def test_pending_migration_is_not_applied
    m = DBGeni::Migration.new('anydir', @valid_migration)
    m.set_pending(@config, @connection)
    assert_equal(false, m.applied?(@config, @connection))
  end

  def test_completed_migration_is_applied
    m = DBGeni::Migration.new('anydir', @valid_migration)
    m.set_completed(@config, @connection)
    assert_equal(true, m.applied?(@config, @connection))
  end

  #############
  # apply!   #
  #############

  def test_apply_good_migration
    m = helper_good_sqlite_migration
    assert_nothing_raised do
      m.apply!(@config, @connection)
    end
    assert_equal('Completed', m.status(@config, @connection))
  end

  def test_apply_good_migration_force_off
    m = helper_good_sqlite_migration
    assert_nothing_raised do
      m.apply!(@config, @connection, false)
    end
    assert_equal('Completed', m.status(@config, @connection))
  end

  def test_apply_already_applied_migration_errors
    m = helper_good_sqlite_migration
    assert_nothing_raised do
      m.apply!(@config, @connection)
    end
    assert_raises DBGeni::MigrationAlreadyApplied do
      m.apply!(@config, @connection)
    end
  end

  def test_apply_migration_with_errors
    m = helper_bad_sqlite_migration
    assert_raises DBGeni::MigrationApplyFailed do
      m.apply!(@config, @connection)
    end
    assert_equal(false, m.applied?(@config, @connection))
    assert_equal('Failed', m.status(@config, @connection))
  end

  def test_apply_migration_with_errors_force_on
    m = helper_bad_sqlite_migration
    assert_nothing_raised do
      m.apply!(@config, @connection, true)
    end
    assert_equal(true, m.applied?(@config, @connection))
    assert_equal('Completed', m.status(@config, @connection))
  end


  #############
  # rollback! #
  #############

  def test_not_applied_migration_will_not_rollback
    # if a migration is partly applied, then it will still rollback, eg if it is PENDING etc
    m = helper_good_sqlite_migration
    assert_raises DBGeni::MigrationNotApplied do
      m.rollback!(@config, @connection)
    end
    m.set_pending(@config, @connection)
    assert_nothing_raised do
      m.rollback!(@config, @connection)
      assert_equal('Rolledback', m.status(@config, @connection))
    end
    m.set_failed(@config, @connection)
    assert_nothing_raised do
      m.rollback!(@config, @connection)
      assert_equal('Rolledback', m.status(@config, @connection))
    end
    m.set_completed(@config, @connection)
    assert_nothing_raised do
      m.rollback!(@config, @connection)
      assert_equal('Rolledback', m.status(@config, @connection))
    end
    m.set_rolledback(@config, @connection)
    assert_raises DBGeni::MigrationNotApplied do
      m.rollback!(@config, @connection)
    end
  end


  def test_apply_rollback_with_errors_raises_exception
    m2 = helper_good_sqlite_migration
    assert_nothing_raised do
      m2.apply!(@config, @connection)
    end
    m  = helper_bad_sqlite_migration
    assert_raises DBGeni::MigrationApplyFailed do
      m.rollback!(@config, @connection)
    end
  end

  def test_apply_rollback_with_errors_and_force_on_raises_no_exception
    m2 = helper_good_sqlite_migration
    assert_nothing_raised do
      m2.apply!(@config, @connection)
    end
    m  = helper_bad_sqlite_migration
    assert_nothing_raised do
      m.rollback!(@config, @connection, true)
    end
    assert_equal(false, m.applied?(@config, @connection))
    assert_equal('Rolledback', m.status(@config, @connection))
  end

  def test_logfile_available_on_apply
    m = helper_good_sqlite_migration
    assert_nothing_raised do
      m.apply!(@config, @connection)
    end
    assert_not_nil(m.logfile)
  end

  def test_logfile_available_on_apply_bad_migration
    m = helper_bad_sqlite_migration
    assert_raises DBGeni::MigrationApplyFailed do
      m.apply!(@config, @connection)
    end
    assert_not_nil(m.logfile)
  end

  def test_logfile_available_on_rollback
    m = helper_good_sqlite_migration
    assert_nothing_raised do
      m.apply!(@config, @connection)
    end
    m = helper_good_sqlite_migration
    assert_nothing_raised do
      m.rollback!(@config, @connection)
    end
    assert_not_nil(m.logfile)
  end

  def test_logfile_available_on_rollback_bad_migration
    m = helper_good_sqlite_migration
    assert_nothing_raised do
      m.apply!(@config, @connection)
    end
    m = helper_bad_sqlite_migration
    assert_raises DBGeni::MigrationApplyFailed do
      m.rollback!(@config, @connection)
    end
    assert_not_nil(m.logfile)
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
