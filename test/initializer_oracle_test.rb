$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$:.unshift File.expand_path(File.dirname(__FILE__))

require 'helper'
require "dbgeni"
require 'test/unit'


class TestInitializerOracle < Test::Unit::TestCase

  include TestHelper

  def setup
    # connect to database and drop the default named migrations table
    @db_connection = helper_oracle_connection #DBGeni::Connector::Oracle.connect('sodonnel', 'sodonnel', 'LOCAL11G')
    begin
      @db_connection.execute("drop table dbgeni_migrations")
    rescue Exception => e
      # warn "Failed to drop dbgeni_migrations: #{e.to_s}"
    end
    @config = helper_oracle_config
  end

  def teardown
  end

  def test_not_initialized_returns_false_when_not_initialized
    @config.database_table 'not_here'
    assert_equal(false, DBGeni::Initializer.initialized?(@db_connection, @config))
  end

  def test_not_initialized_returns_true_when_initialized
    DBGeni::Initializer.initialize(@db_connection, @config)
    assert_equal(true, DBGeni::Initializer.initialized?(@db_connection, @config))
  end

  def test_db_can_be_initialized
    DBGeni::Initializer.initialize(@db_connection, @config)
    results = @db_connection.execute("select table_name from user_tables where table_name = :t", @config.db_table.upcase)
    assert_equal(1, results.length)
  end

  def test_raises_already_initialized
    DBGeni::Initializer.initialize(@db_connection, @config)
    assert_raises DBGeni::DatabaseAlreadyInitialized do
      DBGeni::Initializer.initialize(@db_connection, @config)
    end
  end

end
