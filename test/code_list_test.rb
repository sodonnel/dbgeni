$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$:.unshift File.expand_path(File.dirname(__FILE__))

require 'helper'
require "dbgeni"
require 'test/unit'


class TestCodeList < Test::Unit::TestCase

  include TestHelper

  def setup
    @code_directory = File.expand_path(File.join(File.dirname(__FILE__), "temp", "code"))
    FileUtils.rm_rf(File.join(TestHelper::TEMP_DIR, 'code'))
    FileUtils.mkdir_p(@code_directory)
    %w(p1.prc p2.pks p3.pkb p4.fnc p5.trg p6.abc).each do |f|
      File.open(File.join(@code_directory, f), 'w') do |fh|
        fh.puts "create or replace procedure proc1\nas\nbegin\n  null;\nend;"
      end
    end
    @connection = helper_oracle_connection
    @config     = helper_oracle_config
    begin
      DBGeni::Initializer.initialize(@connection, @config)
    rescue DBGeni::DatabaseAlreadyInitialized
    end
    @connection.execute("delete from #{@config.db_table}")
  end

  def teardown
    FileUtils.rmdir(@code_directory)
  end

  def test_exception_raised_when_code_directory_does_not_exist
    assert_raises DBGeni::CodeDirectoryNotExist do
      ml = DBGeni::CodeList.new('directoryNotExist')
    end
  end

  def test_code_list_loads_code_files
    assert_nothing_raised do
      ml = DBGeni::CodeList.new(@code_directory)
    end
  end

  def test_correct_number_of_code_files_loaded
    # There are 6 files, but one has an invalid extension so shouldn't load
    c = DBGeni::CodeList.new(@code_directory)
    assert_equal(5, c.code.length)
  end

  def test_code_files_that_are_current_are_identified
    c = DBGeni::CodeList.new(@code_directory)
    assert_equal(0, c.current(@config, @connection).length)
    c.code[0].apply!(@config, @connection)
    assert_equal(1, c.current(@config, @connection).length)
  end

  def test_code_files_that_are_outstanding_are_identified
    c = DBGeni::CodeList.new(@code_directory)
    assert_equal(5, c.outstanding(@config, @connection).length)
  end

  
  # def test_applied_migrations_only_selected
  #   ml = DBGeni::MigrationList.new(@migration_directory)
  #   ml.migrations[0].set_completed(@config, @connection)
  #   migs = ml.applied(@config, @connection)
  #   assert_equal(1, migs.length)
  #   assert_equal('201101010000::test_migration_one', migs[0].to_s)
  # end

  # def test_applied_migrations_only_selected
  #   ml = DBGeni::MigrationList.new(@migration_directory)
  #   ml.migrations[0].set_completed(@config, @connection)
  #   migs = ml.applied(@config, @connection)
  #   assert_equal(1, migs.length)
  #   assert_equal('201101010000::test_migration_one', migs[0].to_s)
  # end

  # def test_outstanding_migrations_only_selected
  #   ml = DBGeni::MigrationList.new(@migration_directory)
  #   ml.migrations[0].set_completed(@config, @connection)
  #   # set one as applied, it should never be found. One is NEW
  #   migs = ml.outstanding(@config, @connection)
  #   assert_equal(1, migs.length)
  #   assert_equal('201101020000::test_migration_two', migs[0].to_s)
  #   # Should find rolledback
  #   ml.migrations[1].set_rolledback(@config, @connection)
  #   migs = ml.outstanding(@config, @connection)
  #   assert_equal(1, migs.length)
  #   assert_equal('201101020000::test_migration_two', migs[0].to_s)
  #   # Should find failed
  #   ml.migrations[1].set_failed(@config, @connection)
  #   migs = ml.outstanding(@config, @connection)
  #   assert_equal(1, migs.length)
  #   assert_equal('201101020000::test_migration_two', migs[0].to_s)
  #   # Should find pending
  #   ml.migrations[1].set_pending(@config, @connection)
  #   migs = ml.outstanding(@config, @connection)
  #   assert_equal(1, migs.length)
  #   assert_equal('201101020000::test_migration_two', migs[0].to_s)
  # end

  # def test_applied_and_broken_migrations_only_selected
  #   ml = DBGeni::MigrationList.new(@migration_directory)
  #   ml.migrations[0].set_completed(@config, @connection)
  #   migs = ml.applied_and_broken(@config, @connection)
  #   assert_equal(1, migs.length)
  #   assert_equal('201101010000::test_migration_one', migs[0].to_s)
  #   # Should find pending
  #   ml.migrations[0].set_pending(@config, @connection)
  #   migs = ml.applied_and_broken(@config, @connection)
  #   assert_equal(1, migs.length)
  #   assert_equal('201101010000::test_migration_one', migs[0].to_s)
  #   # Should find failed
  #   ml.migrations[0].set_failed(@config, @connection)
  #   migs = ml.applied_and_broken(@config, @connection)
  #   assert_equal(1, migs.length)
  #   assert_equal('201101010000::test_migration_one', migs[0].to_s)
  #   # Should not find rolledback
  #   ml.migrations[0].set_rolledback(@config, @connection)
  #   migs = ml.applied_and_broken(@config, @connection)
  #   assert_equal(0, migs.length)
  # end


end

