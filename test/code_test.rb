$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$:.unshift File.expand_path(File.dirname(__FILE__))

require 'helper'
require "dbgeni"
require 'test/unit'
require 'mocha'
require 'dbgeni/migrators/oracle'
require 'dbgeni/migrators/mysql'

class TestCode < Test::Unit::TestCase

  include TestHelper

  def setup
    @code = DBGeni::Code.new('directory', 'proc1.prc')
    @code.stubs(:ensure_file_exists).returns(true)
    @code.stubs(:hash).returns('abcdefgh')
    @code.stubs(:convert_code)


    # Instance variables are clobbered after each test so store connection in class var
    @@connection ||= helper_oracle_connection
    @connection = @@connection
    @config     = helper_oracle_config

    FileUtils.mkdir_p(File.join(TEMP_DIR, 'log'))
    begin
      DBGeni::Initializer.initialize(@connection, @config)
    rescue DBGeni::DatabaseAlreadyInitialized
    end
    @connection.execute('delete from dbgeni_migrations')
  end

  def teardown
    # @connection.disconnect
    Mocha::Mockery.instance.stubba.unstub_all
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
             'trg' => 'TRIGGER',
             'typ' => 'TYPE',
             'sql' => 'UNKNOWN'
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
    assert_equal('PROC1', @code.name)
  end

  def test_sets_correct_name_when_file_has_order_prefix
    assert_equal('PROC1', DBGeni::Code.new('directory', '001_proc1.prc').name)
    assert_equal('_PROC1', DBGeni::Code.new('directory', '_proc1.prc').name)
    assert_equal('NEW_PROC1', DBGeni::Code.new('directory', 'new_proc1.prc').name)
  end

  # Cannot stub this one - need to see if the file actually gets hashed!
  def test_file_hash_generated
    helper_good_procedure_file
    c = DBGeni::Code.new(File.join(TestHelper::TEMP_DIR, 'code'), 'proc1.prc')
    assert_not_nil(c.hash)
  end

  def test_insert_applied_db_record
    @code.set_applied(@config, @connection)
    assert_equal('Applied', get_state(@code))
  end

  def test_update_applied_db_record
    @code.set_applied(@config, @connection)
    assert_equal('Applied', get_state(@code))
    assert_nothing_raised do
      @code.set_applied(@config, @connection)
    end
  end

  def test_set_remove_db_record_when_no_record
    @code.set_removed(@config, @connection)
    assert_equal(nil, get_state(@code))
  end

  def test_set_remove_db_record_when_existing_inserted_record
    @code.set_applied(@config, @connection)
    assert_equal('Applied', get_state(@code))
    @code.set_removed(@config, @connection)
    assert_equal(nil, get_state(@code))
  end

  ####################################
  # applied?, outstanding?, current? #
  ####################################

  def test_applied?
    assert_equal(false, @code.applied?(@config, @connection))
    @code.set_applied(@config, @connection)
    assert_equal(true, @code.applied?(@config, @connection))
  end

  def test_outstanding?
    assert_equal(true, @code.outstanding?(@config, @connection))
    @code.set_applied(@config, @connection)
    assert_equal(false, @code.outstanding?(@config, @connection))
  end

  def test_current?
    @code.set_applied(@config, @connection)
    assert_equal(true, @code.current?(@config, @connection))
    # update the hash to something else
    @code.stubs(:hash).returns('abc123456')
    assert_equal(false, @code.current?(@config, @connection))
  end


  ##########
  # apply! #
  ##########

  def test_apply_simple_procedure
    DBGeni::Migrator::Oracle.any_instance.expects(:compile).with(@code)
    DBGeni::Migrator::Oracle.any_instance.expects(:code_errors).returns('')

    assert_nothing_raised do
      @code.apply!(@config, @connection)
    end
    assert_equal(true, @code.current?(@config,@connection))
  end

  def test_apply_when_current_raises_exception
    DBGeni::Migrator::Oracle.any_instance.expects(:compile).with(@code)
    DBGeni::Migrator::Oracle.any_instance.expects(:code_errors).returns('')

    assert_nothing_raised do
      @code.apply!(@config, @connection)
    end
    assert_raises DBGeni::CodeModuleCurrent do
      @code.apply!(@config, @connection)
    end
  end

  def test_apply_when_current_and_force_does_not_raise_exception
    DBGeni::Migrator::Oracle.any_instance.stubs(:compile).with(@code)
    DBGeni::Migrator::Oracle.any_instance.stubs(:code_errors).returns('')

    assert_nothing_raised do
      @code.apply!(@config, @connection)
    end
    assert_nothing_raised do
      @code.apply!(@config, @connection, true)
    end
  end

  def test_apply_when_file_not_exist_raises_exception
    @code = DBGeni::Code.new('directory', 'proc1.prc')
    @code.unstub(:ensure_file_exists)
    assert_raises DBGeni::CodeFileNotExist do
      @code.apply!(@config, @connection)
    end
  end

  ###########
  # remove! #
  ###########

  def test_no_error_when_remove_procedure_that_doesnt_exist
    DBGeni::Migrator::Oracle.any_instance.expects(:remove).with(@code)

    assert_nothing_raised do
      @code.remove!(@config, @connection)
    end
  end

  def test_procedure_removed_sucessfully
    DBGeni::Migrator::Oracle.any_instance.expects(:compile).with(@code)
    DBGeni::Migrator::Oracle.any_instance.expects(:remove).with(@code)
    DBGeni::Migrator::Oracle.any_instance.expects(:code_errors).returns('')

    @code.apply!(@config, @connection)
    assert_equal(true, @code.current?(@config, @connection))
    assert_nothing_raised do
      @code.remove!(@config, @connection)
    end
    assert_equal(false, @code.current?(@config, @connection))
    # ensure procedure removed from database table.
    assert_equal(0, @connection.execute("select count(*) from #{@config.db_table} where migration_name = 'PROC1'")[0][0])
  end

  def test_remove_procedure_when_file_not_exist_raises_exception
    c = DBGeni::Code.new(File.join(TestHelper::TEMP_DIR, 'code'), 'proc2.prc')
    assert_raises DBGeni::CodeFileNotExist do
      c.remove!(@config, @connection)
    end
  end


  ###############
  # Other tests #
  ###############

  def test_logfile_is_available
    DBGeni::Migrator::Oracle.any_instance.expects(:compile).with(@code)
    DBGeni::Migrator::Oracle.any_instance.expects(:logfile).returns('somelog.log')
    DBGeni::Migrator::Oracle.any_instance.expects(:code_errors).returns('')

    assert_nothing_raised do
      @code.apply!(@config, @connection)
    end
    assert_not_nil(@code.logfile)
  end

  def test_error_messages_are_nil_for_good_procedure
    DBGeni::Migrator::Oracle.any_instance.expects(:compile).with(@code)
    DBGeni::Migrator::Oracle.any_instance.expects(:logfile).returns('somelog.log')
    DBGeni::Migrator::Oracle.any_instance.expects(:code_errors).returns(nil)

    assert_nothing_raised do
      @code.apply!(@config, @connection)
    end
    assert_nil(@code.error_messages)
  end

  def test_error_messages_available_for_bad_procedure
    DBGeni::Migrator::Oracle.any_instance.expects(:compile).with(@code)
    DBGeni::Migrator::Oracle.any_instance.expects(:logfile).returns('somelog.log')
    DBGeni::Migrator::Oracle.any_instance.expects(:code_errors).returns('something')

    assert_nothing_raised do
      @code.apply!(@config, @connection)
    end
    assert_not_nil(@code.error_messages)
  end

  def test_migration_error_messages_available_for_bad_procedure_with_exception
    DBGeni::Migrator::Oracle.any_instance.expects(:compile).with(@code).raises(DBGeni::MigrationContainsErrors)
    DBGeni::Migrator::Oracle.any_instance.expects(:logfile).returns('somelog.log')
    DBGeni::Migrator::Oracle.any_instance.expects(:migration_errors).returns('something')

    assert_raises(DBGeni::CodeApplyFailed) do
      @code.apply!(@config, @connection)
    end
    assert_not_nil(@code.error_messages)
  end

  def test_migration_error_messages_available_for_bad_procedure_with_exception_and_force
    DBGeni::Migrator::Oracle.any_instance.expects(:compile).with(@code).raises(DBGeni::MigrationContainsErrors)
    DBGeni::Migrator::Oracle.any_instance.expects(:logfile).returns('somelog.log')
    DBGeni::Migrator::Oracle.any_instance.expects(:migration_errors).returns('something')

    assert_nothing_raised do
      @code.apply!(@config, @connection, true)
    end
    assert_not_nil(@code.error_messages)
  end

  ##### MYSQL
  def test_mysql_migration_error_messages_available_for_bad_procedure
    DBGeni::Migrator::Mysql.any_instance.expects(:compile).with(@code).raises(DBGeni::MigrationContainsErrors)
    DBGeni::Migrator::Mysql.any_instance.expects(:logfile).returns('somelog.log')
    DBGeni::Migrator::Mysql.any_instance.expects(:code_errors).returns('something')
    @config = helper_mysql_config

    assert_raises(DBGeni::CodeApplyFailed) do
      @code.apply!(@config, @connection, false)
    end
    assert_not_nil(@code.error_messages)
  end

  ##### MYSQL
  def test_mysql_migration_error_messages_available_for_bad_procedure_with_force
    DBGeni::Migrator::Mysql.any_instance.expects(:compile).with(@code).raises(DBGeni::MigrationContainsErrors)
    DBGeni::Migrator::Mysql.any_instance.expects(:logfile).returns('somelog.log')
    DBGeni::Migrator::Mysql.any_instance.expects(:code_errors).returns('something')
    @config = helper_mysql_config

    assert_nothing_raised do
      @code.apply!(@config, @connection, true)
    end
    assert_not_nil(@code.error_messages)
  end

  def test_convert_code_is_invoked_on_compile
    # This test is a MESS. At the top convert_code is stubbed out, so in this method, it needs to be
    # unstubbed. However, it seems to trip up Mocha when I do @code.unstub(:convert_code), so I have
    # duplicated a lot of the logic down here.
    code = DBGeni::Code.new('directory', 'proc1.prc')
    code.stubs(:ensure_file_exists).returns(true)
    code.stubs(:hash).returns('abcdefgh')
    DBGeni::FileConverter.expects(:convert).returns('newfile')
    DBGeni::Migrator::Oracle.any_instance.expects(:compile).with(code)
    DBGeni::Migrator::Oracle.any_instance.expects(:code_errors).returns('')

    assert_nothing_raised do
      code.apply!(@config, @connection)
    end
    assert_equal(true, @code.current?(@config,@connection))
    DBGeni::FileConverter.unstub(:convert)
  end

  def test_runable_code_returns_original_file_when_not_converted
    assert_equal(File.join('directory', 'proc1.prc'), @code.runnable_code)
  end

  def test_runable_code_returns_new_file_when_converted
    code = DBGeni::Code.new('directory', 'proc1.prc')
    DBGeni::FileConverter.expects(:convert).returns('newfile')
    code.convert_code(@config)

    assert_equal('newfile', code.runnable_code)
    DBGeni::FileConverter.unstub(:convert)
  end


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
