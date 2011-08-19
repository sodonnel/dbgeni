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
    @config.base_directory = TestHelper::TEMP_DIR
    @connection.execute("delete from #{@config.db_table}")
    @migrator = DBGeni::Migrator.initialize(@config, @connection)
  end

  def teardown
  end

  def test_good_migration_runs_without_error
    migration = helper_good_oracle_migration
    assert_nothing_raised do
      @migrator.apply(migration)
    end
  end

  def test_bad_migration_runs_with_error
    migration = helper_bad_oracle_migration
    assert_raises DBGeni::MigrationContainsErrors do
      @migrator.apply(migration)
    end
  end

  def test_empty_migration_runs_without_error
    migration = helper_empty_oracle_migration
    assert_nothing_raised do
      @migrator.apply(migration)
    end
  end

end
