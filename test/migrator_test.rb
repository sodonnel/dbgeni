$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$:.unshift File.expand_path(File.dirname(__FILE__))

require 'helper'
require "dbgeni"
require 'test/unit'

class TestMigrator < Test::Unit::TestCase

  include TestHelper
  def setup
    @connection       = Object.new 
  end

  def teardown
  end

  def test_sqlite_migrator_loads
    migrator = nil
    assert_nothing_raised do
      migrator = DBGeni::Migrator.initialize(helper_sqlite_config, @connection)
    end
    assert_equal('DBGeni::Migrator::Sqlite', migrator.class.to_s)
  end

  def test_oracle_migrator_loads
    migrator = nil
    assert_nothing_raised do
      migrator = DBGeni::Migrator.initialize(helper_oracle_config, @connection)
    end
    assert_equal('DBGeni::Migrator::Oracle', migrator.class.to_s)
  end

  def test_sybase_migrator_loads
    migrator = nil
    assert_nothing_raised do
      migrator = DBGeni::Migrator.initialize(helper_sybase_config, @connection)
    end
    assert_equal('DBGeni::Migrator::Sybase', migrator.class.to_s)
  end

  def test_mysql_migrator_loads
    migrator = nil
    assert_nothing_raised do
      migrator = DBGeni::Migrator.initialize(helper_mysql_config, @connection)
    end
    assert_equal('DBGeni::Migrator::Mysql', migrator.class.to_s)
  end

end
