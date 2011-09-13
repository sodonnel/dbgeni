$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$:.unshift File.expand_path(File.dirname(__FILE__))

require 'helper'
require 'test/unit'

class TestCLIConfig < Test::Unit::TestCase

  include TestHelper

  def setup
    helper_clean_temp
    helper_sqlite_single_environment_file
  end

  def teardown
  end

  def test_can_list_config_with_specified_file
    response = Kernel.system("#{CLI} config -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
  end

  def test_can_list_config_with_specified_file_long_format
    response = Kernel.system("#{CLI} config --config-file #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
  end

  def test_cannot_list_config_with_invalid_config_file
    response = Kernel.system("#{CLI} config --config-file #{TEMP_DIR}/sqlite.conf.nothere")
    assert_equal(false, response)
  end

  def test_finds_config_file_with_default_name_in_current_directory
    Dir.chdir(TEMP_DIR) do
      File.rename("#{TEMP_DIR}/sqlite.conf", "#{TEMP_DIR}/.dbgeni" )
      response = Kernel.system("#{CLI} config")
      assert_equal(true, response)
    end
  end

  def test_error_when_config_file_has_errors
    helper_sqlite_single_environment_file_with_errors
    response = `#{CLI} config -c #{TEMP_DIR}/sqlite.conf`
    assert_match(/There is an error in the config file/, response)
  end


#  def test_can_list_config_for_specific_environment
#    response = Kernel.system("#{CLI} config development --config-file #{TEMP_DIR}/sqlite.conf")
#    assert_equal(true, response)
#  end
#
#  def test_errors_when_listing_config_for_environment_which_does_not_exist
#    response = Kernel.system("#{CLI} config notthere --config-file #{TEMP_DIR}/sqlite.conf")
#    assert_equal(false, response)
#  end

  def test_help_switch_works
    response = Kernel.system("#{CLI} config --help")
    assert_equal(true, response)
    response = Kernel.system("#{CLI} config -h")
    assert_equal(true, response)
  end

end
