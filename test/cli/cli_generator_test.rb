$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$:.unshift File.expand_path(File.dirname(__FILE__))

require 'helper'
require 'test/unit'

class TestCLIGenerator < Test::Unit::TestCase

  include TestHelper

  def setup
    helper_clean_temp
    helper_sqlite_single_environment_file
  end

  def teardown
  end

  ##############
  # Migrations #
  ##############

  def test_migration_created_successfully
    response = Kernel.system("#{CLI} generate migration my_test_migration -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(true, response)
    # ensure both the up and down file are created
    files = Dir.entries("#{TEMP_DIR}/migrations").grep /\.sql$/
    assert_equal(2, files.length)
    # The one? method returns true if the block returns true only once for all elements.
    assert_equal(true, files.one?{|f| f =~ /_up_my_test_migration.sql$/})
    assert_equal(true, files.one?{|f| f =~ /_down_my_test_migration.sql$/})
  end

  def test_errors_when_no_name_passed
    response = Kernel.system("#{CLI} generate migration -c #{TEMP_DIR}/sqlite.conf")
    assert_equal(false, response)
  end

end
