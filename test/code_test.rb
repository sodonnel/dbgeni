$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$:.unshift File.expand_path(File.dirname(__FILE__))

require 'helper'
require "dbgeni"
require 'test/unit'

class TestCode < Test::Unit::TestCase

  include TestHelper

  def setup
    @connection = helper_oracle_connection
    @config     = helper_oracle_config

    FileUtils.mkdir_p(File.join(TEMP_DIR, 'log'))
    begin
      DBGeni::Initializer.initialize(@connection, @config)
    rescue DBGeni::DatabaseAlreadyInitialized
    end
    @connection.execute('delete from dbgeni_migrations')
  end

  def teardown
  end

  def test_can_initialize_ok
    assert_nothing_raised do
      DBGeni::Code.new('somedirectory', 'package.pkb')
    end
  end

  def test_sets_correct_code_type
    types = {
             'pks' => 'PACKAGE SPEC',
             'pkb' => 'PACKAGE BODY',
             'prc' => 'PROCEDURE',
             'fnc' => 'FUNCTION',
             'trg' => 'TRIGGER'
    }
    types.keys.each do |k|
      c = DBGeni::Code.new('somedirectory', "package.#{k}")
      assert_equal(c.type, types[k])
    end
  end

  def test_exception_raised_when_invalid_code_type
    assert_raises DBGeni::UnknownCodeType do
      c = DBGeni::Code.new('somedirectory', "package.abc")
    end
  end

  def test_sets_correct_name
    c = DBGeni::Code.new('somedirectory', "package.pks")
    assert_equal('PACKAGE', c.name)
  end

  def test_file_hash_generated
    helper_good_procedure_file
    c = DBGeni::Code.new(File.join(TestHelper::TEMP_DIR, 'code'), 'proc1.prc')
    assert_not_nil(c.hash)
  end


  def test_insert_applied_db_record
    helper_good_procedure_file
    c = DBGeni::Code.new(File.join(TestHelper::TEMP_DIR, 'code'), 'proc1.prc')
    c.set_applied(@config, @connection)
    assert_equal('Applied', get_state(c))
  end

  def test_update_applied_db_record
    helper_good_procedure_file
    c = DBGeni::Code.new(File.join(TestHelper::TEMP_DIR, 'code'), 'proc1.prc')
    c.set_applied(@config, @connection)
    assert_equal('Applied', get_state(c))
    assert_nothing_raised do
      c.set_applied(@config, @connection)
    end
  end

  def test_set_remove_db_record_when_no_record
    helper_good_procedure_file
    c = DBGeni::Code.new(File.join(TestHelper::TEMP_DIR, 'code'), 'proc1.prc')
    c.set_removed(@config, @connection)
    assert_equal(nil, get_state(c))
  end

  def test_set_remove_db_record_when_existing_inserted_record
    helper_good_procedure_file
    c = DBGeni::Code.new(File.join(TestHelper::TEMP_DIR, 'code'), 'proc1.prc')
    c.set_applied(@config, @connection)
    assert_equal('Applied', get_state(c))
    c.set_removed(@config, @connection)
    assert_equal(nil, get_state(c))
  end

  ####################################
  # applied?, outstanding?, current? #
  ####################################

  def test_applied?
    helper_good_procedure_file
    c = DBGeni::Code.new(File.join(TestHelper::TEMP_DIR, 'code'), 'proc1.prc')
    assert_equal(false, c.applied?(@config, @connection))
    c.set_applied(@config, @connection)
    assert_equal(true, c.applied?(@config, @connection))
  end

  def test_outstanding?
    helper_good_procedure_file
    c = DBGeni::Code.new(File.join(TestHelper::TEMP_DIR, 'code'), 'proc1.prc')
    assert_equal(true, c.outstanding?(@config, @connection))
    c.set_applied(@config, @connection)
    assert_equal(false, c.outstanding?(@config, @connection))
  end

  def test_current?
    helper_good_procedure_file
    c = DBGeni::Code.new(File.join(TestHelper::TEMP_DIR, 'code'), 'proc1.prc')
    assert_equal(false, c.current?(@config, @connection))
    c.set_applied(@config, @connection)
    assert_equal(true, c.current?(@config, @connection))
    # update the hash to something else
    @connection.execute("update #{@config.db_table} set sequence_or_hash = 'abcd'
                         where migration_name = 'PROC1' and migration_type = 'PROCEDURE'")
    assert_equal(false, c.current?(@config, @connection))
  end


  ##########
  # apply! #
  ##########

  def test_apply_simple_procedure
    helper_good_procedure_file
    c = DBGeni::Code.new(File.join(TestHelper::TEMP_DIR, 'code'), 'proc1.prc')
    assert_nothing_raised do
      c.apply!(@config, @connection)
    end
    assert_equal(true, c.current?(@config,@connection))
  end

  def test_apply_when_current_raises_exception
    helper_good_procedure_file
    c = DBGeni::Code.new(File.join(TestHelper::TEMP_DIR, 'code'), 'proc1.prc')
    assert_nothing_raised do
      c.apply!(@config, @connection)
    end
    assert_raises DBGeni::CodeModuleCurrent do
      c.apply!(@config, @connection)
    end
  end

  def test_apply_when_current_and_force_does_not_raise_exception
    helper_good_procedure_file
    c = DBGeni::Code.new(File.join(TestHelper::TEMP_DIR, 'code'), 'proc1.prc')
    assert_nothing_raised do
      c.apply!(@config, @connection)
    end
    assert_nothing_raised do
      c.apply!(@config, @connection, true)
    end
  end

  def test_apply_when_file_not_exist_raises_exception
    c = DBGeni::Code.new(File.join(TestHelper::TEMP_DIR, 'code'), 'proc2.prc')
    assert_raises DBGeni::CodeFileNotExist do
      c.apply!(@config, @connection)
    end
  end

  ###########
  # remove! #
  ###########



  private

  def get_state(m)
    results = @connection.execute("select migration_state
                                   from #{@config.db_table}
                                   where migration_type  = :type
                                   and   migration_name  = :migration", m.type, m.name)
    if results.length == 1
      results[0][0]
    else
      nil
    end
  end


end
