$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$:.unshift File.expand_path(File.dirname(__FILE__))

require 'helper'
require "dbgeni"
require 'test/unit'


class TestMigrationList < Test::Unit::TestCase

  include TestHelper

  def setup
    @migration_directory = File.expand_path(File.join(File.dirname(__FILE__), "temp", "migrations"))
    FileUtils.rm_rf(File.join(TestHelper::TEMP_DIR, 'migrations'))
    FileUtils.mkdir_p(@migration_directory)
    %w(201101010000_up_test_migration_one.sql 201101010000_down_test_migration_one.sql
       201101020000_up_test_migration_two.sql 201101020000_down_test_migration_two.sql
       201101010000_up_not_a_migration.old).each do |f|
      FileUtils.touch(File.join(@migration_directory, f))
    end
    @connection = helper_sqlite_connection
    @config     = helper_sqlite_config
    begin
      DBGeni::Initializer.initialize(@connection, @config)
    rescue DBGeni::DatabaseAlreadyInitialized
    end
  end

  def teardown
    FileUtils.rmdir(@migration_directory)
  end

  def test_exception_raise_when_migration_does_exist
    assert_raises DBGeni::MigrationDirectoryNotExist do
      ml = DBGeni::MigrationList.new('directoryNotExist')
    end
  end

  def test_migration_list_loads_migrations
    assert_nothing_raised do
      ml = DBGeni::MigrationList.new(@migration_directory)
    end
  end

  def test_correct_number_of_migration_loaded
    ml = DBGeni::MigrationList.new(@migration_directory)
    assert_equal(2, ml.migrations.length)
  end

  def test_applied_migrations_only_selected
    ml = DBGeni::MigrationList.new(@migration_directory)
    ml.migrations[0].set_completed(@config, @connection)
    migs = ml.applied(@config, @connection)
    assert_equal(1, migs.length)
    assert_equal('201101010000::test_migration_one', migs[0].to_s)
  end

  def test_applied_migrations_only_selected
    ml = DBGeni::MigrationList.new(@migration_directory)
    ml.migrations[0].set_completed(@config, @connection)
    migs = ml.applied(@config, @connection)
    assert_equal(1, migs.length)
    assert_equal('201101010000::test_migration_one', migs[0].to_s)
  end

  def test_outstanding_migrations_only_selected
    ml = DBGeni::MigrationList.new(@migration_directory)
    ml.migrations[0].set_completed(@config, @connection)
    # set one as applied, it should never be found. One is NEW
    migs = ml.outstanding(@config, @connection)
    assert_equal(1, migs.length)
    assert_equal('201101020000::test_migration_two', migs[0].to_s)
    # Should find rolledback
    ml.migrations[1].set_rolledback(@config, @connection)
    migs = ml.outstanding(@config, @connection)
    assert_equal(1, migs.length)
    assert_equal('201101020000::test_migration_two', migs[0].to_s)
    # Should find failed
    ml.migrations[1].set_failed(@config, @connection)
    migs = ml.outstanding(@config, @connection)
    assert_equal(1, migs.length)
    assert_equal('201101020000::test_migration_two', migs[0].to_s)
    # Should find pending
    ml.migrations[1].set_pending(@config, @connection)
    migs = ml.outstanding(@config, @connection)
    assert_equal(1, migs.length)
    assert_equal('201101020000::test_migration_two', migs[0].to_s)
  end

  def test_applied_and_broken_migrations_only_selected
    ml = DBGeni::MigrationList.new(@migration_directory)
    ml.migrations[0].set_completed(@config, @connection)
    migs = ml.applied_and_broken(@config, @connection)
    assert_equal(1, migs.length)
    assert_equal('201101010000::test_migration_one', migs[0].to_s)
    # Should find pending
    ml.migrations[0].set_pending(@config, @connection)
    migs = ml.applied_and_broken(@config, @connection)
    assert_equal(1, migs.length)
    assert_equal('201101010000::test_migration_one', migs[0].to_s)
    # Should find failed
    ml.migrations[0].set_failed(@config, @connection)
    migs = ml.applied_and_broken(@config, @connection)
    assert_equal(1, migs.length)
    assert_equal('201101010000::test_migration_one', migs[0].to_s)
    # Should not find rolledback
    ml.migrations[0].set_rolledback(@config, @connection)
    migs = ml.applied_and_broken(@config, @connection)
    assert_equal(0, migs.length)
  end


end

