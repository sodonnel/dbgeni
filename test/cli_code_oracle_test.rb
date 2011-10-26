$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$:.unshift File.expand_path(File.dirname(__FILE__))

require 'dbgeni'
require 'helper'
require 'test/unit'

class TestCLICodeOracleTest < Test::Unit::TestCase

  include TestHelper

  def setup
    helper_clean_temp
    helper_oracle_single_environment_file
    helper_reinitialize_oracle
  end

  def teardown
  end

  ###########################
  # General Error Scenarios #
  ###########################

  def test_error_when_config_file_has_errors
    helper_sqlite_single_environment_file_with_errors
    response = `#{CLI} code list -c #{TEMP_DIR}/sqlite.conf`
    assert_match(/There is an error in the config file/, response)
  end

  def test_errors_when_no_config_file
    response = `#{CLI} code list`
    assert_match(/config file .* does not exist/, response)
  end

  def test_ensure_help_switch_works
    response = `#{CLI} code --help`
    assert_match(/Usage/, response)
    response = `#{CLI} code -h`
    assert_match(/Usage/, response)
  end

  def test_errors_when_no_env_specified_and_many_environments
    helper_sqlite_multiple_environment_file
    response = `#{CLI} code list -c #{TEMP_DIR}/sqlite.conf`
    assert_match(/environment specified and config file defines more than one environment/, response)
  end

  def test_errors_when_env_specified_that_does_not_exist
    helper_sqlite_multiple_environment_file
    response = `#{CLI} code list -c  #{TEMP_DIR}/sqlite.conf -e foobar`
    assert_match(/The environment .* does not exist/, response)
  end

  #########################
  # List Code Modules     #
  #########################

  def test_can_list_code_when_none
    response = Kernel.system("#{CLI} code list -c #{TEMP_DIR}/oracle.conf")
    assert_equal(true, response)
  end

  def test_can_list_code_when_some
    helper_good_procedure_file
    response = Kernel.system("#{CLI} code list -c #{TEMP_DIR}/oracle.conf")
    assert_equal(true, response)
  end

  def test_can_list_outstanding_code_when_none
    response = Kernel.system("#{CLI} code outstanding -c #{TEMP_DIR}/oracle.conf")
    assert_equal(true, response)
  end

  def test_can_list_outstanding_code_when_some
    helper_good_procedure_file
    response = Kernel.system("#{CLI} code outstanding -c #{TEMP_DIR}/oracle.conf")
    assert_equal(true, response)
  end

  def test_can_list_current_code_when_none
    response = Kernel.system("#{CLI} code current -c #{TEMP_DIR}/oracle.conf")
    assert_equal(true, response)
  end

  def test_can_list_current_code_when_some
    helper_good_procedure_file
    response = Kernel.system("#{CLI} code apply all -c #{TEMP_DIR}/oracle.conf")
    assert_equal(true, response)
    response = Kernel.system("#{CLI} code current -c #{TEMP_DIR}/oracle.conf")
    assert_equal(true, response)
  end

  ###############
  # Apply Tests #
  ###############

   def test_apply_all_code_modules_when_none
     response = `#{CLI} code apply all -c #{TEMP_DIR}/oracle.conf`
     assert_match(/There are no outstanding code modules to apply/, response)
   end

   def test_apply_all_code_modules_when_some
     helper_good_procedure_file
     response = Kernel.system("#{CLI} code apply all -c #{TEMP_DIR}/oracle.conf")
     assert_equal(true, response)
   end

   def test_apply_all_code_modules_when_some_but_none_outstanding
     helper_good_procedure_file
     response = Kernel.system("#{CLI} code apply all -c #{TEMP_DIR}/oracle.conf")
     assert_equal(true, response)
     response = Kernel.system("#{CLI} code apply all -c #{TEMP_DIR}/oracle.conf")
     assert_equal(true, response)
   end

   def test_apply_outstanding_code_modules_when_none
     response = `#{CLI} code apply outstanding -c #{TEMP_DIR}/oracle.conf`
     assert_match(/There are no outstanding code modules to apply/, response)
   end

   def test_apply_outstanding_code_modules_when_some
     helper_good_procedure_file
     response = Kernel.system("#{CLI} code apply outstanding -c #{TEMP_DIR}/oracle.conf")
     assert_equal(true, response)
   end

   def test_apply_outstanding_code_modules_when_some_but_none_outstanding
     helper_good_procedure_file
     response = Kernel.system("#{CLI} code apply outstanding -c #{TEMP_DIR}/oracle.conf")
     assert_equal(true, response)
     response = `#{CLI} code apply outstanding -c #{TEMP_DIR}/oracle.conf`
     assert_match(/There are no outstanding code modules to apply/, response)
   end

   def test_apply_specific_code_module
     helper_good_procedure_file
     response = Kernel.system("#{CLI} code apply proc1.prc -c #{TEMP_DIR}/oracle.conf")
     assert_equal(true, response)
   end

   def test_apply_specific_code_module_where_file_not_exist
     helper_good_procedure_file
     response = `#{CLI} code apply proc2.prc -c #{TEMP_DIR}/oracle.conf`
     assert_match(/The code file, .+ does not exist/, response)
   end

   def test_apply_specific_code_module_where_not_outstanding
     helper_good_procedure_file
     response = Kernel.system("#{CLI} code apply outstanding -c #{TEMP_DIR}/oracle.conf")
     assert_equal(true, response)
     response = `#{CLI} code apply proc1.prc -c #{TEMP_DIR}/oracle.conf`
     assert_match(/The code module is already current /, response)
   end

   def test_apply_specific_code_module_where_not_outstanding_force
     helper_good_procedure_file
     response = Kernel.system("#{CLI} code apply outstanding -c #{TEMP_DIR}/oracle.conf")
     assert_equal(true, response)
     response = Kernel.system("#{CLI} code apply proc1.prc -c #{TEMP_DIR}/oracle.conf --force")
     assert_equal(true,response)
   end

   def test_ensure_apply_procedure_with_error_lists_errors
     helper_bad_procedure_file
     response = `#{CLI} code apply outstanding -c #{TEMP_DIR}/oracle.conf`
     assert_match(/with errors/, response)
   end

   ################
   # Remove Tests #
   ################

   def test_remove_all_code_modules_when_none
     response = `#{CLI} code remove all -c #{TEMP_DIR}/oracle.conf`
     assert_match(/There are no code files in the code_directory/, response)
   end

   def test_remove_all_code_modules_when_some_but_not_installed
     helper_good_procedure_file
     response = Kernel.system("#{CLI} code remove all -c #{TEMP_DIR}/oracle.conf")
     assert_equal(true, response)
   end

   def test_remove_all_code_modules_when_some_installed
     helper_good_procedure_file
     response = Kernel.system("#{CLI} code apply outstanding -c #{TEMP_DIR}/oracle.conf")
     assert_equal(true, response)
     response = Kernel.system("#{CLI} code remove all -c #{TEMP_DIR}/oracle.conf")
     assert_equal(true, response)
   end

   def test_remove_specific_code_module_when_not_installed
     helper_good_procedure_file
     response = Kernel.system("#{CLI} code remove proc1.prc -c #{TEMP_DIR}/oracle.conf")
     assert_equal(true, response)
   end

   def test_remove_specific_code_module_when_installed
     helper_good_procedure_file
     response = Kernel.system("#{CLI} code apply outstanding -c #{TEMP_DIR}/oracle.conf")
     assert_equal(true, response)
     response = Kernel.system("#{CLI} code remove proc1.prc -c #{TEMP_DIR}/oracle.conf")
     assert_equal(true, response)
   end

   def test_remove_specific_code_module_which_does_not_exist
     helper_good_procedure_file
     response = `#{CLI} code remove proc2.prc -c #{TEMP_DIR}/oracle.conf`
     assert_match(/The code file, .+ does not exist/, response)
   end

   def test_invalid_remove_command
     response = `#{CLI} code remove allofnothing -c #{TEMP_DIR}/oracle.conf`
     assert_match(/is not a valid command/, response)
   end


end
