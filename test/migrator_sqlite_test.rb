$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$:.unshift File.expand_path(File.dirname(__FILE__))

require 'helper'
require "dbgeni"
require 'test/unit'
require 'dbgeni/migrators/sqlite'
require 'dbgeni/initializers/sqlite'

class TestMigratorSqlite < Test::Unit::TestCase

  include TestHelper

  def setup
    @connection = helper_sqlite_connection
    @config     = helper_sqlite_config
    FileUtils.mkdir_p(File.join(TEMP_DIR, 'log'))
    unless DBGeni::Initializer::Sqlite.initialized?(@connection, @config)
      DBGeni::Initializer::Sqlite.initialize(@connection, @config)
    end
    @connection.execute("delete from #{@config.db_table}")
    begin
      @connection.execute("drop table foo")
    rescue Exception => e
    end
    @migrator = DBGeni::Migrator.initialize(@config, @connection)
  end

  def teardown
  end

  def test_good_migration_runs_without_error
    migration = helper_good_sqlite_migration
    assert_nothing_raised do
      @migrator.apply(migration)
    end
    assert_nothing_raised do
      @migrator.rollback(migration)
    end
  end

  def test_bad_migration_runs_with_error
    migration = helper_bad_sqlite_migration
    assert_raises DBGeni::MigrationContainsErrors do
      @migrator.apply(migration)
    end
    # also ensure that the command after the bad command does not get run
    results = @connection.execute("SELECT name FROM sqlite_master WHERE name = :t", 'foo')
    assert_equal(0, results.length)
    assert_raises DBGeni::MigrationContainsErrors do
      @migrator.rollback(migration)
    end
    results = @connection.execute("SELECT name FROM sqlite_master WHERE name = :t", 'foo')
    assert_equal(0, results.length)
  end

  def test_bad_migration_runs_with_error_force_off
    migration = helper_bad_sqlite_migration
    assert_raises DBGeni::MigrationContainsErrors do
      @migrator.apply(migration, false)
    end
    # also ensure that the command after the bad command does not get run
    results = @connection.execute("SELECT name FROM sqlite_master WHERE name = :t", 'foo')
    assert_equal(0, results.length)
    assert_raises DBGeni::MigrationContainsErrors do
      @migrator.rollback(migration, false)
    end
    results = @connection.execute("SELECT name FROM sqlite_master WHERE name = :t", 'foo')
    assert_equal(0, results.length)
  end


  def test_bad_migration_runs_to_completion_with_force_on
    migration = helper_bad_sqlite_migration
    assert_nothing_raised do
      @migrator.apply(migration, true)
    end
    # also ensure that the command after the bad command does get run
    results = @connection.execute("SELECT name FROM sqlite_master WHERE name = :t", 'foo')
    assert_equal(1, results.length)
    assert_nothing_raised do
      @migrator.rollback(migration, true)
    end
    results = @connection.execute("SELECT name FROM sqlite_master WHERE name = :t", 'foo')
    assert_equal(1, results.length)
  end


  def test_empty_migration_runs_without_error
    migration = helper_empty_sqlite_migration
    assert_nothing_raised do
      @migrator.apply(migration)
    end
    assert_nothing_raised do
      @migrator.rollback(migration)
    end
  end

  def test_logfile_accessible
    migration = helper_good_sqlite_migration
    assert_nothing_raised do
      @migrator.apply(migration)
    end
    assert_not_nil(@migrator.logfile)
  end

end

