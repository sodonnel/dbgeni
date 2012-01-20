$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$:.unshift File.expand_path(File.dirname(__FILE__))

require 'helper'
require "dbgeni"
require 'test/unit'
require 'dbgeni/connectors/sybase'

class TestSybaseConnector < Test::Unit::TestCase

  include TestHelper

  def setup
    @conn = DBGeni::Connector::Sybase.connect('sa', 'sa1234', 'cfg', '10.152.97.152' ,5000)
  end

  def teardown
   # @conn.disconnect
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

  def test_can_create_table
    begin
      @conn.execute('drop table test_tab')
    rescue
    end
    assert_nothing_raised do
      res = @conn.execute('create table test_tab (c1 varchar(10))')
    end
  end

  def test_date_correctly_formatted
    sql = "select #{@conn.date_placeholder(1)}"
    res = @conn.execute(sql, @conn.date_as_string(Time.now))
    assert_equal(1, res.length)
  end

  def test_query_binds_correctly
    return unless @conn
    sql = "select 1 from sysobjects where 1 = ? and 2 = ? and 'abc' = ?"
    results = @conn.execute(sql, 1, 2, 'abc')
    assert_equal(1, results[0][0])
  end

  def test_query_with_no_results_gives_empty_array
    return unless @conn
    sql = "select 1 from sysobjects where 1 = 2"
    results = @conn.execute(sql)
    assert_equal(0, results.length)
  end
end
