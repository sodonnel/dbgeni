$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$:.unshift File.expand_path(File.dirname(__FILE__))

require 'helper'
require "dbgeni"
require 'test/unit'
require 'mocha'


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
    @connection = mock('DBGeni::Connector::Sqlite')
    @config     = mock('DBGeni::Config')
    @config.stubs(:migration_directory).returns(@migration_directory)
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
    ml.migrations.each do |obj|
      obj.stubs(:status).returns(DBGeni::Migration::NEW)
    end
    assert_equal(0, ml.applied(@config, @connection).length)
    ml.migrations[0].stubs(:status).returns(DBGeni::Migration::COMPLETED)
    migs = ml.applied(@config, @connection)
    assert_equal(1, migs.length)
    assert_equal('201101010000::test_migration_one', migs[0].to_s)
  end

  def test_outstanding_migrations_only_selected
    ml = DBGeni::MigrationList.new(@migration_directory)
    ml.migrations.each do |obj|
      obj.stubs(:status).returns(DBGeni::Migration::NEW)
    end

    ml.migrations[0].stubs(:status).returns(DBGeni::Migration::COMPLETED)

    migs = ml.outstanding(@config, @connection)
    assert_equal(1, migs.length)
    assert_equal('201101020000::test_migration_two', migs[0].to_s)

    # Should find rolledback
    ml.migrations[1].stubs(:status).returns(DBGeni::Migration::ROLLEDBACK)
    migs = ml.outstanding(@config, @connection)
    assert_equal(1, migs.length)
    assert_equal('201101020000::test_migration_two', migs[0].to_s)

    # Should find failed
    ml.migrations[1].stubs(:status).returns(DBGeni::Migration::FAILED)
    migs = ml.outstanding(@config, @connection)
    assert_equal(1, migs.length)
    assert_equal('201101020000::test_migration_two', migs[0].to_s)

    # Should find pending
    ml.migrations[1].stubs(:status).returns(DBGeni::Migration::PENDING)
    migs = ml.outstanding(@config, @connection)
    assert_equal(1, migs.length)
    assert_equal('201101020000::test_migration_two', migs[0].to_s)
  end

  def test_applied_and_broken_migrations_only_selected
    ml = DBGeni::MigrationList.new(@migration_directory)
    ml.migrations.each do |obj|
      obj.stubs(:status).returns(DBGeni::Migration::NEW)
    end

    ml.migrations[0].stubs(:status).returns(DBGeni::Migration::COMPLETED)

    migs = ml.applied_and_broken(@config, @connection)
    assert_equal(1, migs.length)
    assert_equal('201101010000::test_migration_one', migs[0].to_s)

    # Should find pending
    ml.migrations[0].stubs(:status).returns(DBGeni::Migration::PENDING)
    migs = ml.applied_and_broken(@config, @connection)
    assert_equal(1, migs.length)
    assert_equal('201101010000::test_migration_one', migs[0].to_s)

    # Should find failed
    ml.migrations[0].stubs(:status).returns(DBGeni::Migration::FAILED)
    migs = ml.applied_and_broken(@config, @connection)
    assert_equal(1, migs.length)
    assert_equal('201101010000::test_migration_one', migs[0].to_s)

    # Should not find rolledback
    ml.migrations[0].stubs(:status).returns(DBGeni::Migration::ROLLEDBACK)
    migs = ml.applied_and_broken(@config, @connection)
    assert_equal(0, migs.length)
  end

  def test_migration_list_returns_correct_migrations
    ml = DBGeni::MigrationList.new(@migration_directory)
    list = ml.list(['201101010000::test_migration_one', '201101020000::test_migration_two'], @config, @connection)
    assert_equal('201101010000_up_test_migration_one.sql', list[0].migration_file)
    assert_equal('201101020000_up_test_migration_two.sql', list[1].migration_file)
  end

  def test_migration_list_throws_when_migration_not_exist
    ml = DBGeni::MigrationList.new(@migration_directory)
    assert_raises DBGeni::MigrationFileNotExist do
      list = ml.list(['201101010000::test_migration_not_there', '201101020000::test_migration_two'], @config, @connection)
    end
  end

  def test_migrations_set_to_type_DML_when_loaded_as_DML
    ml = DBGeni::MigrationList.new_dml_migrations(@migration_directory)
    assert_equal(2, ml.migrations.length)
    assert_equal('DML', ml.migrations.first.migration_type)
  end

end

