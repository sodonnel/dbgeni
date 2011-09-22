$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$:.unshift File.expand_path(File.dirname(__FILE__))

require 'helper'
require 'test/unit'

class TestCLINew < Test::Unit::TestCase

  include TestHelper

  def setup
    helper_clean_temp
  end

  def teardown
  end

  def test_new_installer_directory_created
    response = Kernel.system("#{CLI} new #{TEMP_DIR}/test_structure")
    assert_equal(true, response)
    assert_equal(true, File.directory?("#{TEMP_DIR}/test_structure"))
    assert_equal(true, File.directory?("#{TEMP_DIR}/test_structure"))
    assert_equal(true, File.directory?("#{TEMP_DIR}/test_structure/migrations"))
    assert_equal(true, File.exists?("#{TEMP_DIR}/test_structure/.dbgeni"))
  end

  def test_no_directory_created_when_already_exists
    FileUtils.mkdir_p("#{TEMP_DIR}/test_structure")
    response = Kernel.system("#{CLI} new #{TEMP_DIR}/test_structure")
    assert_equal(false, response)
  end

  def test_config_file_only_created_directory_exists
    FileUtils.mkdir_p("#{TEMP_DIR}/test_structure")
    response = Kernel.system("#{CLI} new-config #{TEMP_DIR}/test_structure")
    assert_equal(true, response)
    assert_equal(true, File.exists?("#{TEMP_DIR}/test_structure/.dbgeni"))
  end

  def test_config_file_fails_to_create_when_directory_does_not_exist
    response = Kernel.system("#{CLI} new-config #{TEMP_DIR}/test_structure")
    assert_equal(false, response)
  end

  def test_help_switch_works
    response = Kernel.system("#{CLI} new --help")
    assert_equal(true, response)
    response = Kernel.system("#{CLI} new -h")
    assert_equal(true, response)
  end

end
