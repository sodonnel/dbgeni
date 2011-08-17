$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$:.unshift File.expand_path(File.dirname(__FILE__))

require 'helper'
require "dbgeni"
require 'test/unit'

class TestMigrator < Test::Unit::TestCase

  include TestHelper
  def setup
    @connection       = helper_sqlite_connection
    @connection_ora   = helper_oracle_connection
    @config           = helper_sqlite_config
    @config_ora  =      helper_oracle_config
  end

  def teardown
  end

  def test_sqlite_migrator_loads
    migrator = nil
    assert_nothing_raised do
      migrator = DBGeni::Migrator.initialize(@config, @connection)
    end
    assert_equal('DBGeni::Migrator::Sqlite', migrator.class.to_s)
  end

  def test_oracle_migrator_loads
    migrator = nil
    assert_nothing_raised do
      migrator = DBGeni::Migrator.initialize(@config_ora, @connection_ora)
    end
    assert_equal('DBGeni::Migrator::Oracle', migrator.class.to_s)
  end


end
