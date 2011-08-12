$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))

require "dbinst"
require 'test/unit'
require 'dbinst/connectors/oracle'

class TestInitializerOracle < Test::Unit::TestCase

  def setup
    # connect to database and drop the default named migrations table
    @db_connection = DBInst::Connector::Oracle.connect('sodonnel', 'sodonnel', 'LOCAL11G')
    begin
      @db_connection.execute("drop table dbinst_migrations")
    rescue Exception => e
      # warn "Failed to drop dbinst_migrations: #{e.to_s}"
    end
    @config = DBInst::Config.new
  end

  def teardown
    begin
      @db_connection.execute("drop table dbinst_migrations")
    rescue
    end
  end

  def test_not_initialized_returns_false_when_not_initialized
    @config.database_table 'not_here'
    assert_equal(false, DBInst::Initializer.initialized?(@db_connection, @config))
  end

  def test_not_initialized_returns_true_when_initialized
    DBInst::Initializer.initialize(@db_connection, @config)
    assert_equal(true, DBInst::Initializer.initialized?(@db_connection, @config))
  end

  def test_db_can_be_initialized
    DBInst::Initializer.initialize(@db_connection, @config)
    results = @db_connection.execute("select table_name from user_tables where table_name = :t", @config.db_table.upcase)
    assert_equal(1, results.length)
  end

  def test_raises_already_initialized
    DBInst::Initializer.initialize(@db_connection, @config)
    assert_raises DBInst::DatabaseAlreadyInitialized do
      DBInst::Initializer.initialize(@db_connection, @config)
    end
  end

end
