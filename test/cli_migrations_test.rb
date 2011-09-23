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

  def test_apply_specific_migration_when_not_exist
    response = Kernel.system("#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    response = `#{CLI} migrations apply 201108190000::not_there -c #{TEMP_DIR}/sqlite.conf`
    assert_match(/The migration file, .* does not exist/, response)
  end

  def test_apply_specific_migration_that_has_already_been_applied
    response = Kernel.system("#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    helper_good_sqlite_migration
    response = Kernel.system("#{CLI} migrations apply 201108190000::test_migration -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    response = `#{CLI} migrations apply 201108190000::test_migration -c #{TEMP_DIR}/sqlite.conf`
    assert_match(/The migration is already applied/, response)
  end

  def test_apply_specific_migration_that_has_already_been_applied
    response = Kernel.system("#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    helper_good_sqlite_migration
    response = Kernel.system("#{CLI} migrations apply 201108190000::test_migration -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    response = `#{CLI} migrations apply 201108190000::test_migration -c #{TEMP_DIR}/sqlite.conf`
    assert_match(/The migration is already applied/, response)
  end

  def test_apply_specific_migration_that_has_already_been_applied_force_on
    response = Kernel.system("#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    helper_good_sqlite_migration
    response = Kernel.system("#{CLI} migrations apply 201108190000::test_migration -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    response = Kernel.system("#{CLI} migrations apply 201108190000::test_migration -c #{TEMP_DIR}/sqlite.conf -f")
    assert_equal(true, response)
  end

  ##########
  # until  #
  ##########

  def test_apply_until_good_migration
    response = Kernel.system("#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    helper_good_sqlite_migration
    response = Kernel.system("#{CLI} migrations apply until 201108190000::test_migration -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
  end

  def test_apply_until_bad_migration
    response = Kernel.system("#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    helper_bad_sqlite_migration
    response = Kernel.system("#{CLI} migrations apply until 201108190000::test_migration -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(false, response)
  end

  def test_apply_until_bad_migration_force_on
    response = Kernel.system("#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    helper_bad_sqlite_migration
    response = Kernel.system("#{CLI} migrations apply until 201108190000::test_migration -c #{TEMP_DIR}/sqlite.conf -f")
    assert_equal(true, response)
  end

  def test_apply_until_migration_that_does_not_exist
    response = Kernel.system("#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    response = `#{CLI} migrations apply until 201108200000::test_migration -c #{TEMP_DIR}/sqlite.conf`
    assert_match(/does not exist or is not outstanding/, response)
  end

  def test_apply_until_migration_with_invalid_name
    response = Kernel.system("#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    response = `#{CLI} migrations apply until 2011000000::test_migration -c #{TEMP_DIR}/sqlite.conf`
    assert_match(/is not a valid migration name/, response)
  end

  def test_apply_until_migration_missing_name
    response = Kernel.system("#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    response = `#{CLI} migrations apply until -c #{TEMP_DIR}/sqlite.conf`
    assert_match(/A migration name must be specified/, response)
  end

  def test_apply_until_migration_many_migrations
    response = Kernel.system("#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    helper_many_good_sqlite_migrations(4)
    response = Kernel.system("#{CLI} migrations apply until 201108190002::test_migration -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
  end

  def test_apply_until_migration_many_bad_migrations
    response = Kernel.system("#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    helper_many_bad_sqlite_migrations(4)
    response = Kernel.system("#{CLI} migrations apply until 201108190002::test_migration -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(false, response)
  end

  def test_apply_until_migration_many_bad_migrations_force_on
    response = Kernel.system("#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    helper_many_bad_sqlite_migrations(4)
    response = Kernel.system("#{CLI} migrations apply until 201108190002::test_migration -c #{TEMP_DIR}/sqlite.conf -f")
    assert_equal(true, response)
  end

  def test_invalid_apply_command
    response = Kernel.system("#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    response = `#{CLI} migrations apply foobar -c #{TEMP_DIR}/sqlite.conf`
    assert_match(/is not a valid command/, response)
  end

  ##################
  # Rollback Tests #
  ##################

  def test_apply_last_rollback_when_none
    response = Kernel.system("#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    response = `#{CLI} migrations rollback last -c #{TEMP_DIR}/sqlite.conf`
    assert_match(/There are no applied migrations to rollback/, response)
  end

  def test_apply_last_rollback_when_some
    response = Kernel.system("#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    helper_good_sqlite_migration
    response = Kernel.system("#{CLI} migrations apply next -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    response = Kernel.system("#{CLI} migrations rollback last -c #{TEMP_DIR}/sqlite.conf")
  end

  def test_rollback_last_migration_with_errors
    response = Kernel.system("#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    helper_good_sqlite_migration
    response = Kernel.system("#{CLI} migrations apply next -c #{TEMP_DIR}/sqlite.conf")
    helper_bad_sqlite_migration
    response = `#{CLI} migrations rollback last -c #{TEMP_DIR}/sqlite.conf`
    assert_match(/There was a problem rolling back/, response)
  end

  def test_rollback_last_migration_with_errors_and_force
    response = Kernel.system("#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    helper_good_sqlite_migration
    response = Kernel.system("#{CLI} migrations apply next -c #{TEMP_DIR}/sqlite.conf")
    helper_bad_sqlite_migration
    response = Kernel.system("#{CLI} migrations rollback last -c #{TEMP_DIR}/sqlite.conf -f")
    assert_equal(true, response)
  end

  def test_rollback_all_migrations_when_none
    response = Kernel.system("#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    response = `#{CLI} migrations rollback all -c #{TEMP_DIR}/sqlite.conf`
    assert_match(/There are no applied migrations to rollback/, response)
  end

  def test_rollback_all_migrations_when_some
    response = Kernel.system("#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    helper_good_sqlite_migration
    response = Kernel.system("#{CLI} migrations apply next -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    response = Kernel.system("#{CLI} migrations rollback all -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
  end

  def test_rollback_all_migrations_with_errors
    response = Kernel.system("#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    helper_good_sqlite_migration
    response = Kernel.system("#{CLI} migrations apply next -c #{TEMP_DIR}/sqlite.conf")
    helper_bad_sqlite_migration
    response = `#{CLI} migrations rollback all -c #{TEMP_DIR}/sqlite.conf`
    assert_match(/There was a problem rolling back/, response)
  end

  def test_rollback_all_migrations_with_errors_and_force
    response = Kernel.system("#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    helper_good_sqlite_migration
    response = Kernel.system("#{CLI} migrations apply next -c #{TEMP_DIR}/sqlite.conf")
    helper_bad_sqlite_migration
    response = Kernel.system("#{CLI} migrations rollback all -c #{TEMP_DIR}/sqlite.conf -f")
    assert_equal(true, response)
  end

  def test_rollback_specific_good_migration
    response = Kernel.system("#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    helper_good_sqlite_migration
    response = Kernel.system("#{CLI} migrations apply 201108190000::test_migration -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    response = Kernel.system("#{CLI} migrations rollback 201108190000::test_migration -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
  end

  def test_rollback_specific_bad_migration
    response = Kernel.system("#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    helper_good_sqlite_migration
    response = Kernel.system("#{CLI} migrations apply 201108190000::test_migration -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    helper_bad_sqlite_migration
    response = `#{CLI} migrations rollback 201108190000::test_migration -c #{TEMP_DIR}/sqlite.conf`
    assert_match(/There was a problem rolling back/, response)
  end

  def test_rollback_specific_bad_migration_with_force
    response = Kernel.system("#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    helper_good_sqlite_migration
    response = Kernel.system("#{CLI} migrations apply 201108190000::test_migration -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    helper_bad_sqlite_migration
    response = Kernel.system("#{CLI} migrations rollback 201108190000::test_migration -c #{TEMP_DIR}/sqlite.conf -f")
    assert_equal(true, response)
  end

  # Would expect this to raise an error indicating the file does not exist,
  # but it doesn't even get to that point as it doesn't get past the 'not applied'
  # check.
  def test_apply_specific_rollback_when_not_exist
    response = Kernel.system("#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    response = `#{CLI} migrations rollback 201108190000::not_there -c #{TEMP_DIR}/sqlite.conf`
    assert_match(/has not been applied so cannot be rolledback/, response)
  end

  def test_rollback_migration_that_has_not_been_applied
    response = Kernel.system("#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    helper_good_sqlite_migration
    response = `#{CLI} migrations rollback 201108190000::test_migration -c #{TEMP_DIR}/sqlite.conf`
    assert_match(/has not been applied so cannot be rolledback/, response)
  end

  def test_rollback_migration_that_has_already_been_rolledback
    response = Kernel.system("#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    helper_good_sqlite_migration
    response = Kernel.system("#{CLI} migrations apply 201108190000::test_migration -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    response = Kernel.system("#{CLI} migrations rollback 201108190000::test_migration -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    response = `#{CLI} migrations rollback 201108190000::test_migration -c #{TEMP_DIR}/sqlite.conf`
    assert_match(/has not been applied so cannot be rolledback/, response)
  end

  def test_rollback_specific_migration_that_has_already_been_rolledback_force_on
    response = Kernel.system("#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    helper_good_sqlite_migration
    response = Kernel.system("#{CLI} migrations apply 201108190000::test_migration -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    response = Kernel.system("#{CLI} migrations rollback 201108190000::test_migration -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    response = Kernel.system("#{CLI} migrations rollback 201108190000::test_migration -c #{TEMP_DIR}/sqlite.conf -f")
    assert_equal(true, response)
  end

  def test_invalid_rollback_command
    response = Kernel.system("#{CLI} initialize -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    response = `#{CLI} migrations rollback foobar -c #{TEMP_DIR}/sqlite.conf`
    assert_match(/is not a valid command/, response)
  end

end
