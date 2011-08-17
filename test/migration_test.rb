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
    begin
      DBGeni::Initializer.initialize(@connection, @config)
    rescue DBGeni::DatabaseAlreadyInitialized
    end
  end

  def teardown
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
