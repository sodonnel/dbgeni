$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))

require "dbinst"
require 'test/unit'
require "dbinst/connectors/oracle.rb"

class TestOracleConnector < Test::Unit::TestCase

  def setup
    # TODO - handle these tests when database is not available
    @conn = DBInst::Connector::Oracle.connect('sodonnel', 'sodonnel', 'LOCAL11G')
  end

  def teardown
    @conn.disconnect
  end

  def test_can_connect_successfully
    return unless @conn
    # connect is done in setup ... should really be an assert nothing raised or something
    assert_equal(1, 1)
  end

  def test_can_ping_connection_successfully
    return unless @conn
    assert_equal(true, @conn.ping)
  end

  def test_query_binds_correctly
    return unless @conn
    sql = "select * from dual where 1 = :bind1 and 2 = :bind2"
    results = @conn.execute(sql, 1, 2)
    assert_equal('X', results[0][0])
  end

  def test_query_with_no_results_gives_empty_array
    return unless @conn
    sql = "select * from dual where 1 = 2"
    results = @conn.execute(sql)
    assert_equal(0, results.length)
  end
end
