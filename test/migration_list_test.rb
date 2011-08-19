$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))

require "dbgeni"
require 'test/unit'


class TestMigrationList < Test::Unit::TestCase

  def setup
    @migration_directory = File.expand_path(File.join(File.dirname(__FILE__), "temp", "migrations"))
    FileUtils.rm_rf(File.join(TestHelper::TEMP_DIR, 'migrations'))
    FileUtils.mkdir_p(@migration_directory)
    %w(201101010000_up_test_migration_one.sql 201101010000_down_test_migration_one.sql
       201101020000_up_test_migration_two.sql 201101020000_down_test_migration_two.sql
       201101010000_up_not_a_migration.old).each do |f|
      FileUtils.touch(File.join(@migration_directory, f))
    end
  end

  def teardown
    FileUtils.rmdir(@migration_directory)
  end

  def test_exception_raise_when_migration_does_exist
    assert_raises DBGeni::MigrationDirectoryNotExist do
      ml = DBGeni::MigrationList.new('directoryNotExist')
    end
  end

  def test_migration_list_loads_migrations
    assert_nothing_raised do
      ml = DBGeni::MigrationList.new(@migration_directory)
    end
  end

  def test_correct_number_of_migration_loaded
    ml = DBGeni::MigrationList.new(@migration_directory)
    assert_equal(2, ml.migrations.length)
  end

end

