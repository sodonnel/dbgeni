$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$:.unshift File.expand_path(File.dirname(__FILE__))

require 'helper'

require "dbgeni"
require 'test/unit'
require 'dbgeni/migrators/oracle'

class TestMigratorOracle < Test::Unit::TestCase

  include TestHelper

  def setup
    @connection = helper_oracle_connection
    @config     = helper_oracle_config
    @connection.execute("delete from #{@config.db_table}")
    begin
      # used in bad migration tests with force on
      @connection.execute("drop table foo")
    rescue Exception => e
    end
    @migrator = DBGeni::Migrator.initialize(@config, @connection)
  end

  def teardown
  end

  def test_good_migration_runs_without_error
    migration = helper_good_oracle_migration
    assert_nothing_raised do
      @migrator.apply(migration)
    end
    assert_nothing_raised do
      @migrator.rollback(migration)
    end

  end

  def test_bad_migration_runs_with_error
    migration = helper_bad_oracle_migration
    assert_raises DBGeni::MigrationContainsErrors do
      @migrator.apply(migration)
    end
    # ensure the migration steps after error don't run
    results = @connection.execute("SELECT table_name FROM user_tables WHERE table_name = upper(:t)", 'foo')
    assert_equal(0, results.length)
    assert_raises DBGeni::MigrationContainsErrors do
      @migrator.rollback(migration)
    end
    results = @connection.execute("SELECT table_name FROM user_tables WHERE table_name = upper(:t)", 'foo')
    assert_equal(0, results.length)
  end

  def test_bad_migration_runs_with_error_with_force_off
    migration = helper_bad_oracle_migration
    assert_raises DBGeni::MigrationContainsErrors do
      @migrator.apply(migration, false)
    end
    # ensure the migration steps after error don't run
    results = @connection.execute("SELECT table_name FROM user_tables WHERE table_name = upper(:t)", 'foo')
    assert_equal(0, results.length)
    assert_raises DBGeni::MigrationContainsErrors do
      @migrator.rollback(migration, false)
    end
    results = @connection.execute("SELECT table_name FROM user_tables WHERE table_name = upper(:t)", 'foo')
    assert_equal(0, results.length)
  end


  def test_bad_migration_runs_to_completion_with_force_on
    migration = helper_bad_oracle_migration
    assert_nothing_raised do
      @migrator.apply(migration, true)
    end
    # ensure the migration steps after error run
    results = @connection.execute("SELECT table_name FROM user_tables WHERE table_name = upper(:t)", 'foo')
    assert_equal(1, results.length)
    assert_nothing_raised do
      @migrator.rollback(migration, true)
    end
    results = @connection.execute("SELECT table_name FROM user_tables WHERE table_name = upper(:t)", 'foo')
    assert_equal(1, results.length)
  end


  def test_empty_migration_runs_without_error
    migration = helper_empty_oracle_migration
    assert_nothing_raised do
      @migrator.apply(migration)
    end
    assert_nothing_raised do
      @migrator.rollback(migration)
    end

  end

  def test_good_procedure_loads_without_error
    code = helper_good_procedure_file
    assert_nothing_raised do
      @migrator.compile(code)
    end
  end

  def test_bad_procedure_loads_without_error
    code = helper_bad_procedure_file
    assert_nothing_raised do
      @migrator.compile(code)
    end
  end


end
