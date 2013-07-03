$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$:.unshift File.expand_path(File.dirname(__FILE__))

require 'helper'
require 'test/unit'

class TestCLIInitialize < Test::Unit::TestCase

  include TestHelper

  def setup
    helper_clean_temp
    helper_sqlite_single_environment_file
    helper_oracle_single_environment_file
    helper_mysql_single_environment_file
    @dbs = %w(sqlite oracle mysql)
    @dbs.each do |db|
      begin
        conn = self.send("helper_#{db}_connection".intern)
        conn.execute("drop table dbgeni_migrations")
        conn.disconnect
      rescue Exception => e
      end
    end
  end

  def teardown
  end

  def test_database_can_be_initialized
    @dbs.each do |db|
      response = Kernel.system("#{CLI} initialize -c  #{TEMP_DIR}/#{db}.conf")
      assert_equal(true, response, db)
    end
  end

  def test_database_can_be_initialized_many_environments
    @dbs.each do |db|
      self.send("helper_#{db}_multiple_environment_file".intern)
      response = Kernel.system("#{CLI} initialize -c  #{TEMP_DIR}/#{db}.conf -e development")
      assert_equal(true, response)
    end
  end

  def test_errors_when_no_env_specified_and_many_environments
    @dbs.each do |db|
      self.send("helper_#{db}_multiple_environment_file".intern)
      response = `#{CLI} initialize -c #{TEMP_DIR}/#{db}.conf`
      assert_match(/environment specified and config file defines more than one environment/, response)
    end
  end

  def test_errors_when_env_specified_that_does_not_exist
    @dbs.each do |db|
      self.send("helper_#{db}_multiple_environment_file".intern)
      response = `#{CLI} initialize -c  #{TEMP_DIR}/#{db}.conf -e foobar`
      assert_match(/The environment .* does not exist/, response)
    end
  end

  def test_errors_when_db_already_initialized
    @dbs.each do |db|
      response = Kernel.system("#{CLI} initialize -c  #{TEMP_DIR}/#{db}.conf")
      assert_equal(true, response)
      response = `#{CLI} initialize -c #{TEMP_DIR}/#{db}.conf`
      assert_match(/The Database has already been initialized/, response)
    end
  end

  def test_errors_when_no_config_file
    response = `#{CLI} initialize`
    assert_match(/config file .* does not exist/, response)
  end

  def test_error_when_config_file_has_errors
    helper_sqlite_single_environment_file_with_errors
    response = `#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf`
    assert_match(/There is an error in the config file/, response)
  end

  def test_ensure_help_switch_works
    response = `#{CLI} initialize --help`
    assert_match(/Usage/, response)
    response = `#{CLI} initialize -h`
    assert_match(/Usage/, response)
  end

  def test_user_and_password_can_be_passed_on_command_line
    helper_oracle_single_environment_file_no_user_pass
    response = Kernel.system("#{CLI} initialize -c  #{TEMP_DIR}/oracle.conf -u #{ORA_USER} -p #{ORA_PASSWORD}")
    assert_equal(true, response)
  end


end
