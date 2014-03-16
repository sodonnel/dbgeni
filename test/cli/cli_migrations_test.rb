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
    helper_sqlite_single_environment_file_bad_plugin_directory
    helper_oracle_single_environment_file
    helper_mysql_single_environment_file
    helper_reinitialize_oracle
    helper_reinitialize_sqlite
    helper_reinitialize_mysql
    @dbs = %w(sqlite oracle mysql)
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
    @dbs.each do |db|
      response = Kernel.system("#{CLI} migrations list -c #{TEMP_DIR}/#{db}.conf")
      assert_equal(true, response)
    end
  end

  def test_can_list_migrations_when_some
    @dbs.each do |db|
      self.send("helper_good_#{db}_migration".intern)
      response = Kernel.system("#{CLI} migrations list -c #{TEMP_DIR}/#{db}.conf")
      assert_equal(true, response)
    end
  end

  def test_can_list_outstanding_migrations_when_none
    @dbs.each do |db|
      response = Kernel.system("#{CLI} migrations outstanding -c #{TEMP_DIR}/#{db}.conf")
      assert_equal(true, response, db)
    end
  end

  def test_can_list_outstanding_migrations_when_some
    @dbs.each do |db|
      self.send("helper_good_#{db}_migration".intern)
      response = Kernel.system("#{CLI} migrations outstanding -c #{TEMP_DIR}/#{db}.conf")
      assert_equal(true, response)
    end
  end

  def test_can_list_applied_migrations_when_none
    @dbs.each do |db|
      response = Kernel.system("#{CLI} migrations applied -c #{TEMP_DIR}/#{db}.conf")
      assert_equal(true, response)
    end
  end

  def test_can_list_applied_migrations_when_some
    @dbs.each do |db|
      self.send("helper_good_#{db}_migration".intern)
      response = Kernel.system("#{CLI} migrations apply all -c #{TEMP_DIR}/#{db}.conf")
      assert_equal(true, response)
      response = Kernel.system("#{CLI} migrations applied -c #{TEMP_DIR}/#{db}.conf")
      assert_equal(true, response)
    end
  end

  ###############
  # Apply Tests #
  ###############

  def test_apply_next_migration_when_none
    @dbs.each do |db|
      response = `#{CLI} migrations apply next -c #{TEMP_DIR}/#{db}.conf`
      assert_match(/There are no outstanding migrations to apply/, response)
    end
  end

  def test_apply_next_migration_when_some
    @dbs.each do |db|
      self.send("helper_good_#{db}_migration".intern)
      response = Kernel.system("#{CLI} migrations apply next -c #{TEMP_DIR}/#{db}.conf")
      assert_equal(true, response)
    end
  end

  def test_apply_next_migration_with_errors
    @dbs.each do |db|
      self.send("helper_bad_#{db}_migration".intern)
      response = `#{CLI} migrations apply next -c #{TEMP_DIR}/#{db}.conf`
      assert_match(/There was a problem applying/, response)
    end
  end

  def test_apply_next_migration_with_errors_and_force
    @dbs.each do |db|
      self.send("helper_bad_#{db}_migration".intern)
      response = Kernel.system("#{CLI} migrations apply next -c #{TEMP_DIR}/#{db}.conf -f")
      assert_equal(true, response)
    end
  end

  def test_apply_all_migrations_when_none
    @dbs.each do |db|
      response = `#{CLI} migrations apply all -c #{TEMP_DIR}/#{db}.conf`
      assert_match(/There are no outstanding migrations to apply/, response)
    end
  end

  def test_apply_all_migrations_when_some
    @dbs.each do |db|
      self.send("helper_good_#{db}_migration".intern)
      response = Kernel.system("#{CLI} migrations apply all -c #{TEMP_DIR}/#{db}.conf")
      assert_equal(true, response)
    end
  end

  def test_apply_all_migrations_with_errors
    @dbs.each do |db|
      self.send("helper_bad_#{db}_migration".intern)
      response = `#{CLI} migrations apply all -c #{TEMP_DIR}/#{db}.conf`
      assert_match(/There was a problem applying/, response)
    end
  end

  def test_apply_all_migrations_with_errors_and_force
    @dbs.each do |db|
      self.send("helper_bad_#{db}_migration".intern)
      response = Kernel.system("#{CLI} migrations apply all -c #{TEMP_DIR}/#{db}.conf -f")
      assert_equal(true, response)
    end
  end

  def test_apply_specific_good_migration
    @dbs.each do |db|
      self.send("helper_good_#{db}_migration".intern)
      response = Kernel.system("#{CLI} migrations apply 201108190000::test_migration -c #{TEMP_DIR}/#{db}.conf")
      assert_equal(true, response)
    end
  end

  def test_apply_specific_bad_migration
    @dbs.each do |db|
      self.send("helper_bad_#{db}_migration".intern)
      response = Kernel.system("#{CLI} migrations apply 201108190000::test_migration -c #{TEMP_DIR}/#{db}.conf")
      assert_equal(false, response)
    end
  end

  def test_apply_specific_bad_migration_with_force
    @dbs.each do |db|
      self.send("helper_bad_#{db}_migration".intern)
      response = Kernel.system("#{CLI} migrations apply 201108190000::test_migration -c #{TEMP_DIR}/#{db}.conf -f")
      assert_equal(true, response)
    end
  end

  def test_apply_specific_migration_when_not_exist
    @dbs.each do |db|
      response = `#{CLI} migrations apply 201108190000::not_there -c #{TEMP_DIR}/#{db}.conf`
      assert_match(/The migration file .* does not exist/, response, db)
    end
  end

  def test_apply_specific_migration_that_has_already_been_applied
    @dbs.each do |db|
      self.send("helper_good_#{db}_migration".intern)
      response = Kernel.system("#{CLI} migrations apply 201108190000::test_migration -c #{TEMP_DIR}/#{db}.conf")
      assert_equal(true, response, db)
      response = `#{CLI} migrations apply 201108190000::test_migration -c #{TEMP_DIR}/#{db}.conf`
      assert_match(/The migration is already applied/, response, db)
    end
  end

  def test_apply_specific_migration_that_has_already_been_applied_force_on
    @dbs.each do |db|
      self.send("helper_good_#{db}_migration".intern)
      response = Kernel.system("#{CLI} migrations apply 201108190000::test_migration -c #{TEMP_DIR}/#{db}.conf")
      assert_equal(true, response)
      response = Kernel.system("#{CLI} migrations apply 201108190000::test_migration -c #{TEMP_DIR}/#{db}.conf -f")
      assert_equal(true, response)
    end
  end

  ##########
  # until  #
  ##########

  def test_apply_until_good_migration
    @dbs.each do |db|
      self.send("helper_good_#{db}_migration".intern)
      response = Kernel.system("#{CLI} migrations apply until 201108190000::test_migration -c #{TEMP_DIR}/#{db}.conf")
      assert_equal(true, response)
    end
  end

  def test_apply_until_bad_migration
    @dbs.each do |db|
      self.send("helper_bad_#{db}_migration".intern)
      response = Kernel.system("#{CLI} migrations apply until 201108190000::test_migration -c #{TEMP_DIR}/#{db}.conf")
      assert_equal(false, response)
    end
  end

  def test_apply_until_bad_migration_force_on
    @dbs.each do |db|
      self.send("helper_bad_#{db}_migration".intern)
      response = Kernel.system("#{CLI} migrations apply until 201108190000::test_migration -c #{TEMP_DIR}/#{db}.conf -f")
      assert_equal(true, response)
    end
  end

  def test_apply_until_migration_that_does_not_exist
    @dbs.each do |db|
      response = `#{CLI} migrations apply until 201108200000::test_migration -c #{TEMP_DIR}/#{db}.conf`
      assert_match(/does not exist or is not outstanding/, response)
    end
  end

  def test_apply_until_migration_with_invalid_name
    @dbs.each do |db|
      response = `#{CLI} migrations apply until 2011000000::test_migration -c #{TEMP_DIR}/#{db}.conf`
      assert_match(/is not a valid migration name/, response)
    end
  end

  def test_apply_until_migration_missing_name
    @dbs.each do |db|
      response = `#{CLI} migrations apply until -c #{TEMP_DIR}/sqlite.conf`
      assert_match(/A migration name must be specified/, response)
    end
  end

  def test_apply_until_migration_many_migrations
    @dbs.each do |db|
      self.send("helper_many_good_#{db}_migrations".intern, 4)
      response = Kernel.system("#{CLI} migrations apply until 201108190002::test_migration -c #{TEMP_DIR}/#{db}.conf")
      assert_equal(true, response)
    end
  end

  def test_apply_until_migration_many_bad_migrations
    @dbs.each do |db|
      self.send("helper_many_bad_#{db}_migrations".intern, 4)
      response = Kernel.system("#{CLI} migrations apply until 201108190002::test_migration -c #{TEMP_DIR}/#{db}.conf")
      assert_equal(false, response)
    end
  end

  def test_apply_until_migration_many_bad_migrations_force_on
    @dbs.each do |db|
      self.send("helper_many_bad_#{db}_migrations".intern, 4)
      response = Kernel.system("#{CLI} migrations apply until 201108190002::test_migration -c #{TEMP_DIR}/#{db}.conf -f")
      assert_equal(true, response)
    end
  end

  ############################
  # Milestone

  def test_apply_until_milestone_when_milestone_not_exist
    @dbs.each do |db|
      response = `#{CLI} migrations apply milestone rel1 -c #{TEMP_DIR}/#{db}.conf`
      assert_match(/The milestone .* does not exist/, response)
    end
  end

  def test_apply_until_milestone_when_milestone_not_specified
    @dbs.each do |db|
      response = `#{CLI} migrations apply milestone -c #{TEMP_DIR}/#{db}.conf`
      assert_match(/A milestone must be specified/, response)
    end
  end

  def test_apply_until_milestone_when_milestone_file_empty
    @dbs.each do |db|
      FileUtils.touch(File.join(TEMP_DIR, 'migrations', 'rel1.milestone'))
      response = `#{CLI} migrations apply milestone rel1 -c #{TEMP_DIR}/#{db}.conf`
      assert_match(/The milestone does not contain a valid migration/, response)
    end
  end

  def test_apply_until_milestone_when_non_existent_migration_in_file
    File.open(File.join(TEMP_DIR, 'migrations', 'rel1.milestone'), 'w') do |f|
      f.puts '201001011431_up_something.sql'
    end
    @dbs.each do |db|
      response = `#{CLI} migrations apply milestone rel1 -c #{TEMP_DIR}/#{db}.conf`
      assert_match(/.* does not exist or is not outstanding/, response)
    end
  end

  def test_apply_until_milestone_when_badly_formed_migration_in_file
    File.open(File.join(TEMP_DIR, 'migrations', 'rel1.milestone'), 'w') do |f|
      f.puts 'jibberish'
    end
    @dbs.each do |db|
      response = `#{CLI} migrations apply milestone rel1 -c #{TEMP_DIR}/#{db}.conf`
      assert_match(/The milestone does not contain a valid migration/, response)
    end
  end

  def test_apply_until_milestone
    helper_many_good_sqlite_migrations(4)
    response = Kernel.system("#{CLI} generate milestone rel1 201108190002::test_migration -c #{TEMP_DIR}/sqlite.conf")
    @dbs.each do |db|
      self.send("helper_many_good_#{db}_migrations".intern, 4)
      assert_equal(true, response, db)
      response = Kernel.system("#{CLI} migrations apply milestone rel1 -c #{TEMP_DIR}/#{db}.conf")
      assert_equal(true, response, db)
    end
  end

  #######################
  # invalid commands

  def test_invalid_apply_command
    response = `#{CLI} migrations apply foobar -c #{TEMP_DIR}/sqlite.conf`
    assert_match(/is not a valid command/, response)
  end

  ######################
  #
  def test_bad_migration_includes_logfile
    @dbs.each do |db|
      self.send("helper_bad_#{db}_migration".intern)
      response = `#{CLI} migrations apply all -c #{TEMP_DIR}/#{db}.conf`
      assert_match(/Errors in .*\.sql/, response)
    end
  end

  ##################
  # Rollback Tests #
  ##################

  def test_apply_last_rollback_when_none
    @dbs.each do |db|
      response = `#{CLI} migrations rollback last -c #{TEMP_DIR}/#{db}.conf`
      assert_match(/There are no applied migrations to rollback/, response)
    end
  end

  def test_apply_last_rollback_when_some
    @dbs.each do |db|
      self.send("helper_good_#{db}_migration".intern)
      response = Kernel.system("#{CLI} migrations apply next -c #{TEMP_DIR}/#{db}.conf")
      assert_equal(true, response)
      response = Kernel.system("#{CLI} migrations rollback last -c #{TEMP_DIR}/#{db}.conf")
    end
  end

  def test_rollback_last_migration_with_errors
    @dbs.each do |db|
      self.send("helper_good_#{db}_migration".intern)
      response = Kernel.system("#{CLI} migrations apply next -c #{TEMP_DIR}/#{db}.conf")
      self.send("helper_bad_#{db}_migration".intern)
      response = `#{CLI} migrations rollback last -c #{TEMP_DIR}/#{db}.conf`
      assert_match(/There was a problem rolling back/, response)
    end
  end

  def test_rollback_last_migration_with_errors_and_force
    @dbs.each do |db|
      self.send("helper_good_#{db}_migration".intern)
      response = Kernel.system("#{CLI} migrations apply next -c #{TEMP_DIR}/#{db}.conf")
      self.send("helper_bad_#{db}_migration".intern)
      response = Kernel.system("#{CLI} migrations rollback last -c #{TEMP_DIR}/#{db}.conf -f")
      assert_equal(true, response)
    end
  end

  def test_rollback_all_migrations_when_none
    @dbs.each do |db|
      response = `#{CLI} migrations rollback all -c #{TEMP_DIR}/#{db}.conf`
      assert_match(/There are no applied migrations to rollback/, response)
    end
  end

  def test_rollback_all_migrations_when_some
    @dbs.each do |db|
      self.send("helper_good_#{db}_migration".intern)
      response = Kernel.system("#{CLI} migrations apply next -c #{TEMP_DIR}/#{db}.conf")
      assert_equal(true, response)
      response = Kernel.system("#{CLI} migrations rollback all -c #{TEMP_DIR}/#{db}.conf")
      assert_equal(true, response)
    end
  end

  def test_rollback_all_migrations_with_errors
    @dbs.each do |db|
      self.send("helper_good_#{db}_migration".intern)
      response = Kernel.system("#{CLI} migrations apply next -c #{TEMP_DIR}/#{db}.conf")
      self.send("helper_bad_#{db}_migration".intern)
      response = `#{CLI} migrations rollback all -c #{TEMP_DIR}/#{db}.conf`
      assert_match(/There was a problem rolling back/, response)
    end
  end

  def test_rollback_all_migrations_with_errors_and_force
    @dbs.each do |db|
      self.send("helper_good_#{db}_migration".intern)
      response = Kernel.system("#{CLI} migrations apply next -c #{TEMP_DIR}/#{db}.conf")
      self.send("helper_bad_#{db}_migration".intern)
      response = Kernel.system("#{CLI} migrations rollback all -c #{TEMP_DIR}/#{db}.conf -f")
      assert_equal(true, response)
    end
  end

  def test_rollback_specific_good_migration
    @dbs.each do |db|
      self.send("helper_good_#{db}_migration".intern)
      response = Kernel.system("#{CLI} migrations apply 201108190000::test_migration -c #{TEMP_DIR}/#{db}.conf")
      assert_equal(true, response)
      response = Kernel.system("#{CLI} migrations rollback 201108190000::test_migration -c #{TEMP_DIR}/#{db}.conf")
      assert_equal(true, response)
    end
  end


  def test_rollback_specific_bad_migration
    @dbs.each do |db|
      self.send("helper_good_#{db}_migration".intern)
      response = Kernel.system("#{CLI} migrations apply 201108190000::test_migration -c #{TEMP_DIR}/#{db}.conf")
      assert_equal(true, response)
      self.send("helper_bad_#{db}_migration".intern)
      response = `#{CLI} migrations rollback 201108190000::test_migration -c #{TEMP_DIR}/#{db}.conf`
      assert_match(/There was a problem rolling back/, response)
    end
  end

  def test_rollback_specific_bad_migration_with_force
    @dbs.each do |db|
      self.send("helper_good_#{db}_migration".intern)
      response = Kernel.system("#{CLI} migrations apply 201108190000::test_migration -c #{TEMP_DIR}/#{db}.conf")
      assert_equal(true, response)
      self.send("helper_bad_#{db}_migration".intern)
      response = Kernel.system("#{CLI} migrations rollback 201108190000::test_migration -c #{TEMP_DIR}/#{db}.conf -f")
      assert_equal(true, response)
    end
  end

  def test_apply_specific_rollback_when_not_exist
    @dbs.each do |db|
      response = `#{CLI} migrations rollback 201108190000::not_there -c #{TEMP_DIR}/#{db}.conf`
      assert_match(/The migration file .+ does not exist/, response)
    end
  end

  def test_rollback_migration_that_has_not_been_applied
    @dbs.each do |db|
      self.send("helper_good_#{db}_migration".intern)
      response = `#{CLI} migrations rollback 201108190000::test_migration -c #{TEMP_DIR}/#{db}.conf`
      assert_match(/has not been applied so cannot be rolledback/, response)
    end
  end

  def test_rollback_migration_that_has_already_been_rolledback
    @dbs.each do |db|
      self.send("helper_good_#{db}_migration".intern)
      response = Kernel.system("#{CLI} migrations apply 201108190000::test_migration -c #{TEMP_DIR}/#{db}.conf")
      assert_equal(true, response)
      response = Kernel.system("#{CLI} migrations rollback 201108190000::test_migration -c #{TEMP_DIR}/#{db}.conf")
      assert_equal(true, response)
      response = `#{CLI} migrations rollback 201108190000::test_migration -c #{TEMP_DIR}/#{db}.conf`
      assert_match(/has not been applied so cannot be rolledback/, response)
    end
  end

  def test_rollback_migration_that_has_already_been_rolledback_force_on
    @dbs.each do |db|
      self.send("helper_good_#{db}_migration".intern)
      response = Kernel.system("#{CLI} migrations apply 201108190000::test_migration -c #{TEMP_DIR}/#{db}.conf")
      assert_equal(true, response)
      response = Kernel.system("#{CLI} migrations rollback 201108190000::test_migration -c #{TEMP_DIR}/#{db}.conf")
      assert_equal(true, response)
      response = Kernel.system("#{CLI} migrations rollback 201108190000::test_migration -c #{TEMP_DIR}/#{db}.conf -f")
      assert_equal(true, response)
    end
  end

  ##########
  # until  #
  ##########

  def test_rollback_until_good_migration
    @dbs.each do |db|
      self.send("helper_good_#{db}_migration".intern)
      response = Kernel.system("#{CLI} migrations apply until 201108190000::test_migration -c #{TEMP_DIR}/#{db}.conf")
      assert_equal(true, response)
      response = Kernel.system("#{CLI} migrations rollback until 201108190000::test_migration -c #{TEMP_DIR}/#{db}.conf")
      assert_equal(true, response)
    end
  end

  def test_rollback_until_bad_migration
    @dbs.each do |db|
      self.send("helper_many_good_#{db}_migrations".intern, 2)
      response = Kernel.system("#{CLI} migrations apply until 201108190001::test_migration -c #{TEMP_DIR}/#{db}.conf")
      assert_equal(true, response)
      self.send("helper_many_bad_#{db}_migrations".intern, 2)
      response = Kernel.system("#{CLI} migrations rollback until 201108190000::test_migration -c #{TEMP_DIR}/#{db}.conf")
      assert_equal(false, response)
    end
  end

  def test_rollback_until_bad_migration_force_on
    @dbs.each do |db|
      self.send("helper_many_good_#{db}_migrations".intern, 2)
      response = Kernel.system("#{CLI} migrations apply until 201108190001::test_migration -c #{TEMP_DIR}/#{db}.conf")
      assert_equal(true, response)
      self.send("helper_many_bad_#{db}_migrations".intern, 2)
      response = Kernel.system("#{CLI} migrations rollback until 201108190000::test_migration -c #{TEMP_DIR}/#{db}.conf -f")
      assert_equal(true, response)
    end
  end

  def test_rollback_until_migration_that_does_not_exist
    @dbs.each do |db|
      response = `#{CLI} migrations rollback until 201108200000::test_migration -c #{TEMP_DIR}/#{db}.conf`
      assert_match(/has not been applied so cannot be rolledback/, response)
    end
  end

  def test_rollback_until_migration_with_invalid_name
    @dbs.each do |db|
      response = `#{CLI} migrations rollback until 2011000000::test_migration -c #{TEMP_DIR}/#{db}.conf`
      assert_match(/is not a valid migration name/, response)
    end
  end

  def test_rollback_until_migration_missing_name
    @dbs.each do |db|
      response = `#{CLI} migrations rollback until -c #{TEMP_DIR}/#{db}.conf`
      assert_match(/A migration name must be specified/, response)
    end
  end

  def test_rollback_until_migration_many_migrations
    @dbs.each do |db|
      self.send("helper_many_good_#{db}_migrations".intern, 4)
      response = Kernel.system("#{CLI} migrations apply all -c #{TEMP_DIR}/#{db}.conf")
      assert_equal(true, response)
      response = Kernel.system("#{CLI} migrations rollback until 201108190002::test_migration -c #{TEMP_DIR}/#{db}.conf")
      assert_equal(true, response)
    end
  end

  def test_rollback_until_migration_many_bad_migrations
    @dbs.each do |db|
      self.send("helper_many_good_#{db}_migrations".intern, 4)
      response = Kernel.system("#{CLI} migrations apply until 201108190002::test_migration -c #{TEMP_DIR}/#{db}.conf")
      assert_equal(true, response)
      self.send("helper_many_bad_#{db}_migrations".intern, 4)
      response = Kernel.system("#{CLI} migrations apply until 201108190002::test_migration -c #{TEMP_DIR}/#{db}.conf")
      assert_equal(false, response)
    end
  end

  def test_rollback_until_migration_many_bad_migrations_force_on
    @dbs.each do |db|
      self.send("helper_many_good_#{db}_migrations".intern, 4)
      response = Kernel.system("#{CLI} migrations apply until 201108190002::test_migration -c #{TEMP_DIR}/#{db}.conf")
      assert_equal(true, response)
      self.send("helper_many_bad_#{db}_migrations".intern, 4)
      response = Kernel.system("#{CLI} migrations rollback until 201108190002::test_migration -c #{TEMP_DIR}/#{db}.conf -f")
      assert_equal(true, response)
    end
  end

  #####################################
  ##  Milestones

  # Rollback until milestone is basically the same as rollback until, so test it
  # all gets started correctly.

  def test_rollback_until_milestone_when_no_milestone_specified
    @dbs.each do |db|
      response = `#{CLI} migrations rollback milestone -c #{TEMP_DIR}/#{db}.conf`
      assert_match(/You must specify a milestone/, response)
    end
  end

  def test_rollback_until_milestone_when_milestone_not_exist
    @dbs.each do |db|
      response = `#{CLI} migrations rollback milestone not_here -c #{TEMP_DIR}/#{db}.conf`
      assert_match(/The milestone .+ does not exist/, response)
    end
  end

  def test_rollback_until_milestone_when_milestone_file_empty
    @dbs.each do |db|
      FileUtils.touch(File.join(TEMP_DIR, 'migrations', 'rel1.milestone'))
      response = `#{CLI} migrations rollback milestone rel1 -c #{TEMP_DIR}/#{db}.conf`
      assert_match(/The milestone does not contain a valid migration/, response)
    end
  end

  def test_rollback_until_milestone_when_non_existent_migration_in_file
    @dbs.each do |db|
      File.open(File.join(TEMP_DIR, 'migrations', 'rel1.milestone'), 'w') do |f|
        f.puts '201001011431_up_something.sql'
      end
      response = `#{CLI} migrations rollback milestone rel1 -c #{TEMP_DIR}/#{db}.conf`
      assert_match(/has not been applied so cannot be rolledback/, response)
    end
  end

  def test_rollback_until_milestone_when_badly_formed_migration_in_file
    @dbs.each do |db|
      File.open(File.join(TEMP_DIR, 'migrations', 'rel1.milestone'), 'w') do |f|
        f.puts 'jibberish'
      end
      response = `#{CLI} migrations rollback milestone rel1 -c #{TEMP_DIR}/#{db}.conf`
      assert_match(/The milestone does not contain a valid migration/, response)
    end
  end

  def test_rollback_until_milestone
    # need to generate the files and then the milestone as the milestone generator
    # errors if you try to generate a milestone for a migration that doesn't exist
    helper_many_good_sqlite_migrations(4)
    response = Kernel.system("#{CLI} generate milestone rel1 201108190002::test_migration -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    @dbs.each do |db|
      self.send("helper_many_good_#{db}_migrations".intern, 4)
      response = Kernel.system("#{CLI} migrations apply all 201108190002::test_migration -c #{TEMP_DIR}/#{db}.conf")
      assert_equal(true, response)
      response = Kernel.system("#{CLI} migrations rollback milestone rel1 -c #{TEMP_DIR}/#{db}.conf")
      assert_equal(true, response)
    end
  end


  def test_rollback_migration_that_errors_includes_logfile
    @dbs.each do |db|
      self.send("helper_good_#{db}_migration".intern)
      response = Kernel.system("#{CLI} migrations apply all -c #{TEMP_DIR}/#{db}.conf")
      self.send("helper_bad_#{db}_migration".intern)
      response = `#{CLI} migrations rollback all -c #{TEMP_DIR}/#{db}.conf`
      assert_match(/Errors in .+\.sql.*/, response)
    end
  end


#  def test_rollback_until_migration_missing_migration_file
#
#  end


  ##################################

  def test_invalid_rollback_command
    response = `#{CLI} migrations rollback foobar -c #{TEMP_DIR}/sqlite.conf`
    assert_match(/is not a valid command/, response)
  end

  def test_invalid_plugin_directory
    helper_many_good_sqlite_migrations(4)
    response = `#{CLI} migrations apply next -c #{TEMP_DIR}/sqlite_bad_plugin.conf`
    assert_match(/The plugin directory specified in config is not accessable/, response)
  end

  def test_user_and_password_can_be_passed_on_command_line
    helper_oracle_single_environment_file_no_user_pass
    self.send("helper_good_oracle_migration".intern)
    response = Kernel.system("#{CLI} migrations outstanding -c #{TEMP_DIR}/oracle.conf -u #{ORA_USER} -p #{ORA_PASSWORD}")
    assert_equal(true, response)
  end


end
