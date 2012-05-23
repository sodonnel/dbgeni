$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$:.unshift File.expand_path(File.dirname(__FILE__))

require 'helper'
require "dbgeni"
require 'test/unit'

class TestMysqlConnector < Test::Unit::TestCase

  include TestHelper

  def setup
    @conn = helper_mysql_connection
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

  def test_can_create_table
    begin
      @conn.execute('drop table test_tab')
    rescue Exception => e
    end
    assert_nothing_raised do
      res = @conn.execute('create table test_tab (c1 varchar(10))')
    end
  end

  def test_query_binds_correctly
    return unless @conn
    sql = "select 'X' from dual where 1 = ? and 2 = ?"
    results = @conn.execute(sql, 1, 2)
    assert_equal('X', results[0][0])
  end

  def test_query_with_no_results_gives_empty_array
    return unless @conn
    sql = "select 'X' from dual where 1 = 2"
    results = @conn.execute(sql)
    assert_equal(0, results.length)
  end
end
