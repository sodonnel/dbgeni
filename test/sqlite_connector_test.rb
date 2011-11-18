$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$:.unshift File.expand_path(File.dirname(__FILE__))

require 'helper'
require "dbgeni"
require 'test/unit'

class TestSqliteConnector < Test::Unit::TestCase

  include TestHelper

  def setup
    # TODO - handle these tests when database is not available
    @conn = helper_sqlite_connection
    begin
      # Create a fake DUAL table so the tests can behave in the same way as the Oracle
      # tests work.
      @conn.execute("create table dual (dummy char(1))")
      @conn.execute("insert into dual (dummy) values ('X')")
    rescue Exception => e
      puts e.to_s
      raise
    end
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

  def test_query_with_results_and_many_cols
    return unless @conn
    sql = "select 'hello', 1, 12.34 from dual"
    results = @conn.execute(sql)
    assert_equal(1, results.length)
    assert_equal('hello', results[0][0])
    assert_equal(1, results[0][1])
    assert_equal(12.34, results[0][2])
  end


  def test_db_file_path_plain_filename
    path = DBGeni::Connector::Sqlite.db_file_path('/base', 'db.sqlite')
    assert_equal('/base/db.sqlite', path)
  end

  def test_db_file_path_relative_filename
    path = DBGeni::Connector::Sqlite.db_file_path('/base', './db.sqlite')
    assert_equal('/base/./db.sqlite', path)
  end

  def test_db_file_path_absolute_filename
    path = DBGeni::Connector::Sqlite.db_file_path('/base', '/db.sqlite')
    assert_equal('/db.sqlite', path)
  end

  def test_db_file_path_absolute_filename_windows
    path = DBGeni::Connector::Sqlite.db_file_path('/base', 'C:\db.sqlite')
    assert_equal('C:\db.sqlite', path)
  end


end
