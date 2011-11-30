$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$:.unshift File.expand_path(File.dirname(__FILE__))

require 'helper'
require "dbgeni"
require 'test/unit'
require 'dbgeni/migrators/sybase'
require 'dbgeni/initializers/sybase'

class TestMigratorSybase < Test::Unit::TestCase

  include TestHelper

  def setup
    @connection = helper_sybase_connection #DBGeni::Connector::Sybase.connect('sa', 'sa1234', 'cfg', '10.152.97.152' ,5000)
    @config     = helper_sybase_config
    FileUtils.mkdir_p(File.join(TEMP_DIR, 'log'))
    unless DBGeni::Initializer::Sybase.initialized?(@connection, @config)
      DBGeni::Initializer::Sybase.initialize(@connection, @config)
    end
    @connection.execute("delete from #{@config.db_table}")
    begin
      @connection.execute("drop table foo")
    rescue Exception => e
    end
    begin
      @connection.execute("drop procedure proc1")
    rescue Exception => e
    end
    begin
      @connection.execute("drop function func1")
    rescue Exception => e
    end
    begin
      @connection.execute("drop trigger trg1")
    rescue Exception => e
    end
    @migrator = DBGeni::Migrator.initialize(@config, @connection)
  end

  def teardown
  end

  def test_good_migration_runs_without_error
    migration = helper_good_sybase_migration
    assert_nothing_raised do
      @migrator.apply(migration)
    end
    assert_nothing_raised do
      @migrator.rollback(migration)
    end
  end

  def test_bad_migration_runs_with_error
    # reusing sqlite migration ...
    migration = helper_bad_sybase_migration
    assert_raises DBGeni::MigrationContainsErrors do
      @migrator.apply(migration)
    end
    # For sybase, the command after the error will get run
    # isql does not give you a way to stop that. This is different to all the other
    # databases.
    results = @connection.execute("select name from sysobjects where name = 'foo'")
    assert_equal(1, results.length)
    assert_raises DBGeni::MigrationContainsErrors do
      @migrator.rollback(migration)
    end
  end

  def test_bad_migration_runs_to_completion_force_on
    migration = helper_bad_sybase_migration
    assert_nothing_raised do
      @migrator.apply(migration, true)
    end
    # For sybase, the command after the error will get run
    # isql does not give you a way to stop that. This is different to all the other
    # databases.
    results = @connection.execute("select name from sysobjects where name = 'foo'")
    assert_equal(1, results.length)
    assert_nothing_raised do
      @migrator.rollback(migration, true)
    end
  end


  def test_empty_migration_runs_without_error
    migration = helper_empty_sqlite_migration
    assert_nothing_raised do
      @migrator.apply(migration)
    end
    assert_nothing_raised do
      @migrator.rollback(migration)
    end
  end

  def test_logfile_accessible
    migration = helper_good_sybase_migration
    assert_nothing_raised do
      @migrator.apply(migration)
    end
    assert_not_nil(@migrator.logfile)
  end

  def test_error_message_retrieved_on_bad_migration
    migration = helper_bad_sybase_migration
    assert_raises DBGeni::MigrationContainsErrors do
      @migrator.apply(migration)
    end
    assert_match(/^Msg/, @migrator.migration_errors)
  end

  def test_empty_error_message_retrieved_on_good_migration
    migration = helper_good_sybase_migration
    assert_nothing_raised do
      @migrator.apply(migration)
    end
    assert_equal('', @migrator.migration_errors)
  end

#### code tests

  
  # def test_no_code_errors_reported_for_good_procedure
  #   code = helper_mysql_good_procedure_file
  #   assert_nothing_raised do
  #     @migrator.compile(code)
  #   end
  #   assert_nil(@migrator.code_errors)
  # end

  # def test_code_errors_reported_for_bad_procedure
  #   code = helper_bad_procedure_file
  #   assert_raises DBGeni::MigrationContainsErrors do
  #     @migrator.compile(code)
  #   end
  #   assert_not_nil(@migrator.code_errors)
  # end

  # def test_no_error_dropping_procedure_that_is_not_on_database
  #   code = helper_mysql_good_procedure_file
  #   assert_nothing_raised do
  #     @migrator.remove(code)
  #   end
  # end

  # def test_procedure_is_dropped_successfully
  #   code = helper_mysql_good_procedure_file
  #   assert_nothing_raised do
  #     @migrator.compile(code)
  #     assert_equal(1, @connection.execute("show procedure status like 'proc1'").length)
  #     @migrator.remove(code)
  #   end
  #   assert_equal(0, @connection.execute("show procedure status like 'proc1'").length)
  # end

  # def test_no_code_errors_reported_for_good_function
  #   code = helper_mysql_good_function_file
  #   assert_nothing_raised do
  #     @migrator.compile(code)
  #   end
  #   assert_nil(@migrator.code_errors)
  # end

  # def test_code_errors_reported_for_bad_function
  #   code = helper_mysql_bad_function_file
  #   assert_raises DBGeni::MigrationContainsErrors do
  #     @migrator.compile(code)
  #   end
  #   assert_not_nil(@migrator.code_errors)
  # end

  # def test_no_error_dropping_function_that_is_not_on_database
  #   code = helper_mysql_good_function_file
  #   assert_nothing_raised do
  #     @migrator.remove(code)
  #   end
  # end

  # def test_function_is_dropped_successfully
  #   code = helper_mysql_good_function_file
  #   assert_nothing_raised do
  #     @migrator.compile(code)
  #     assert_equal(1, @connection.execute("show function status like 'func1'").length)
  #     @migrator.remove(code)
  #   end
  #   assert_equal(0, @connection.execute("show function status like 'func1'").length)
  # end

  # def test_no_code_errors_reported_for_good_trigger
  #   code = helper_mysql_good_trigger_file
  #   @connection.execute('create table foo (c1 varchar(10))')
  #   assert_nothing_raised do
  #     @migrator.compile(code)
  #   end
  #   assert_nil(@migrator.code_errors)
  #   # show triggers like needs the table name , not the trigger name
  #   assert_equal(1, @connection.execute("show triggers like 'foo'").length)
  # end

  # def test_code_errors_reported_for_bad_trigger
  #   code = helper_mysql_bad_trigger_file
  #   @connection.execute('create table foo (c1 varchar(10))')
  #   assert_raises DBGeni::MigrationContainsErrors do
  #     @migrator.compile(code)
  #   end
  #   assert_not_nil(@migrator.code_errors)
  # end

  # def test_no_error_dropping_trigger_that_is_not_on_database
  #   code = helper_mysql_good_trigger_file
  #   assert_nothing_raised do
  #     @migrator.remove(code)
  #   end
  # end

  # def test_trigger_is_dropped_successfully
  #   @connection.execute('create table foo (c1 varchar(10))')
  #   code = helper_mysql_good_trigger_file
  #   assert_nothing_raised do
  #     @migrator.compile(code)
  #     assert_equal(1, @connection.execute("show triggers like 'foo'").length)
  #     @migrator.remove(code)
  #   end
  #   assert_equal(0, @connection.execute("show triggers like 'foo'").length)
  # end


end

