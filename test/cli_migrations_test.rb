$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$:.unshift File.expand_path(File.dirname(__FILE__))

require 'dbgeni'
require 'helper'
require 'test/unit'

class TestCLIMigrations < Test::Unit::TestCase

  include TestHelper

  def setup
    helper_clean_temp
    helper_sqlite_single_environment_file
  end

  def teardown
  end

  ###########################
  # General Error Scenarios #
  ###########################

  def test_error_when_config_file_has_errors
    helper_sqlite_single_environment_file_with_errors
    response = `#{CLI} migrations list -c #{TEMP_DIR}/sqlite.conf`
    assert_match(/There is an error in the config file/, response)
  end

  def test_errors_when_no_config_file
    response = `#{CLI} migrations list`
    assert_match(/config file .* does not exist/, response)
  end

  def test_ensure_help_switch_works
    response = `#{CLI} migrations --help`
    assert_match(/Usage/, response)
    response = `#{CLI} migrations -h`
    assert_match(/Usage/, response)
  end

  def test_errors_when_no_env_specified_and_many_environments
    helper_sqlite_multiple_environment_file
    response = `#{CLI} migrations list -c #{TEMP_DIR}/sqlite.conf`
    assert_match(/environment specified and config file defines more than one environment/, response)
  end

  def test_errors_when_env_specified_that_does_not_exist
    helper_sqlite_multiple_environment_file
    response = `#{CLI} migrations list -c  #{TEMP_DIR}/sqlite.conf -e foobar`
    assert_match(/The environment .* does not exist/, response)
  end

  #########################
  # List Migrations
  #########################

  def test_can_list_migrations_when_none
    response = Kernel.system("#{CLI} migrations list -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
  end

  def test_can_list_migrations_when_some
    helper_good_sqlite_migration
    response = Kernel.system("#{CLI} migrations list -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
  end

  def test_can_list_outstanding_migrations_when_none
    response = Kernel.system("#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    response = Kernel.system("#{CLI} migrations outstanding -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
  end

  def test_can_list_outstanding_migrations_when_some
    response = Kernel.system("#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    helper_good_sqlite_migration
    response = Kernel.system("#{CLI} migrations outstanding -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
  end

  def test_can_list_applied_migrations_when_none
    response = Kernel.system("#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    response = Kernel.system("#{CLI} migrations applied -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
  end

  def test_can_list_applied_migrations_when_some
    response = Kernel.system("#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    helper_good_sqlite_migration
    response = Kernel.system("#{CLI} migrations apply all -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    response = Kernel.system("#{CLI} migrations applied -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
  end

  ###############
  # Apply Tests #
  ###############

  def test_apply_next_migration_when_none
    response = Kernel.system("#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    response = `#{CLI} migrations apply next -c #{TEMP_DIR}/sqlite.conf`
    assert_match(/There are no outstanding migrations to apply/, response)
  end

  def test_apply_next_migration_when_some
    response = Kernel.system("#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    helper_good_sqlite_migration
    response = Kernel.system("#{CLI} migrations apply next -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
  end

  def test_apply_next_migration_with_errors
    response = Kernel.system("#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    helper_bad_sqlite_migration
    response = `#{CLI} migrations apply next -c #{TEMP_DIR}/sqlite.conf`
    assert_match(/There was a problem applying/, response)
  end

  def test_apply_next_migration_with_errors_and_force
    response = Kernel.system("#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    helper_bad_sqlite_migration
    response = Kernel.system("#{CLI} migrations apply next -c #{TEMP_DIR}/sqlite.conf -f")
    assert_equal(true, response)
  end

  def test_apply_all_migrations_when_none
    response = Kernel.system("#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    response = `#{CLI} migrations apply all -c #{TEMP_DIR}/sqlite.conf`
    assert_match(/There are no outstanding migrations to apply/, response)
  end

  def test_apply_all_migrations_when_some
    response = Kernel.system("#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    helper_good_sqlite_migration
    response = Kernel.system("#{CLI} migrations apply all -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
  end

  def test_apply_all_migrations_with_errors
    response = Kernel.system("#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    helper_bad_sqlite_migration
    response = `#{CLI} migrations apply all -c #{TEMP_DIR}/sqlite.conf`
    assert_match(/There was a problem applying/, response)
  end

  def test_apply_all_migrations_with_errors_and_force
    response = Kernel.system("#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    helper_bad_sqlite_migration
    response = Kernel.system("#{CLI} migrations apply all -c #{TEMP_DIR}/sqlite.conf -f")
    assert_equal(true, response)
  end

  def test_apply_specific_good_migration
    response = Kernel.system("#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    helper_good_sqlite_migration
    response = Kernel.system("#{CLI} migrations apply 201108190000::test_migration -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
  end

  def test_apply_specific_bad_migration
    response = Kernel.system("#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    helper_bad_sqlite_migration
    response = Kernel.system("#{CLI} migrations apply 201108190000::test_migration -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(false, response)
  end

  def test_apply_specific_bad_migration_with_force
    response = Kernel.system("#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    helper_bad_sqlite_migration
    response = Kernel.system("#{CLI} migrations apply 201108190000::test_migration -c #{TEMP_DIR}/sqlite.conf -f")
    assert_equal(true, response)
  end

 # TODO start here Wednesday ...

  def test_apply_specific_migration_when_not_exist
  end

  def test_apply_specific_migration_that_has_already_been_applied
  end

  def test_invalid_apply_command
  end

  ##################
  # Rollback Tests #
  ##################


end
