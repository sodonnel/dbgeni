$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$:.unshift File.expand_path(File.dirname(__FILE__))

require 'helper'
require "dbgeni"
require 'test/unit'
require 'mocha'


class TestCodeList < Test::Unit::TestCase

  include TestHelper

  def setup
    @code_directory = File.expand_path(File.join(File.dirname(__FILE__), "temp", "code"))
    FileUtils.rm_rf(File.join(TestHelper::TEMP_DIR, 'code'))
    FileUtils.mkdir_p(@code_directory)
    %w(p1.prc p2.pks p3.pkb p4.fnc p5.trg p6.typ p7.sql p8.abc).each do |f|
      File.open(File.join(@code_directory, f), 'w') do |fh|
        fh.puts "create or replace procedure proc1\nas\nbegin\n  null;\nend;"
      end
    end
    @connection = mock('DBGeni::Connector::Oracle')
    @config     = mock('DBGeni::Config')
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
    # There are 8 files, but one has an invalid extension so shouldn't load
    c = DBGeni::CodeList.new(@code_directory)
    assert_equal(7, c.code.length)
  end

  def test_code_files_that_are_current_are_identified
    c = DBGeni::CodeList.new(@code_directory)
    c.code.each do |obj|
      obj.stubs(:current?).with(@config, @connection).returns(false)
    end
    assert_equal(0, c.current(@config, @connection).length)
    c.code[0].stubs(:current?).returns(true)
    assert_equal(1, c.current(@config, @connection).length)
  end

  def test_code_files_that_are_outstanding_are_identified
    c = DBGeni::CodeList.new(@code_directory)
    c.code.each do |obj|
      obj.expects(:current?).returns(false)
    end
    assert_equal(7, c.outstanding(@config, @connection).length)
  end

  def test_files_with_ordering_prefix_ordered_first
    File.open(File.join(@code_directory, '001_p5.prc'), 'w') do |fh|
      fh.puts "create or replace procedure proc5\nas\nbegin\n  null;\nend;"
    end
    c = DBGeni::CodeList.new(@code_directory)
    assert_equal(c.code[0].filename, '001_p5.prc')
  end

  def test_current_files_with_ordering_prefix_ordered_first
    File.open(File.join(@code_directory, '001_p5.prc'), 'w') do |fh|
      fh.puts "create or replace procedure proc5\nas\nbegin\n  null;\nend;"
    end
    c = DBGeni::CodeList.new(@code_directory)
    c.code.each {|c| c.stubs(:current?).with(@config, @connection).returns(true) }
    current_code = c.current(@config, @connection)
    assert_equal(current_code[0].filename, '001_p5.prc')
    assert_equal(current_code[1].filename, 'p1.prc')
  end

  def test_outstanding_files_with_ordering_prefix_ordered_first
    File.open(File.join(@code_directory, '001_p5.prc'), 'w') do |fh|
      fh.puts "create or replace procedure proc5\nas\nbegin\n  null;\nend;"
    end
    c = DBGeni::CodeList.new(@code_directory)
    c.code.each {|c| c.stubs(:current?).with(@config, @connection).returns(false) }
    outstanding_code = c.outstanding(@config, @connection)
    assert_equal(outstanding_code[0].filename, '001_p5.prc')
    assert_equal(outstanding_code[1].filename, 'p1.prc')
  end

end

