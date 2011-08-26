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
    unless DBGeni::Initializer::Sqlite.initialized?(@connection, @config)
      DBGeni::Initializer::Sqlite.initialize(@connection, @config)
    end
    @connection.execute("delete from #{@config.db_table}")
    @migrator = DBGeni::Migrator.initialize(@config, @connection)
  end

  def teardown
  end

  def test_good_migration_runs_without_error
    migration = helper_good_sqlite_migration
    assert_nothing_raised do
      @migrator.apply(migration)
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
  end

  def test_empty_migration_runs_without_error
    migration = helper_empty_sqlite_migration
    assert_nothing_raised do
      @migrator.apply(migration)
    end
  end

end

