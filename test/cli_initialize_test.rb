$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$:.unshift File.expand_path(File.dirname(__FILE__))

require 'helper'
require 'test/unit'

class TestCLIInitialize < Test::Unit::TestCase

  include TestHelper

  def setup
    helper_clean_temp
    helper_sqlite_single_environment_file
  end

  def teardown
  end

  def test_database_can_be_initialized
    response = Kernel.system("#{CLI} initialize -c  #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
  end

  def test_database_can_be_initialized_many_environments
    helper_sqlite_multiple_environment_file
    response = Kernel.system("#{CLI} initialize -c  #{TEMP_DIR}/sqlite.conf -e development")
    assert_equal(true, response)
  end

  def test_errors_when_no_env_specified_and_many_environments
    helper_sqlite_multiple_environment_file
    response = `#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf`
    assert_match(/environment specified and config file defines more than one environment/, response)
  end

  def test_errors_when_env_specified_that_does_not_exist
    helper_sqlite_multiple_environment_file
    response = `#{CLI} initialize -c  #{TEMP_DIR}/sqlite.conf -e foobar`
    assert_match(/The environment .* does not exist/, response)
  end

  def test_errors_when_db_already_initialized
    response = Kernel.system("#{CLI} initialize -c  #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    response = `#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf`
    assert_match(/The Database has already been initialized/, response)
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

end
