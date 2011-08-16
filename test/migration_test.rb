$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))

require "dbgeni"
require 'test/unit'

class TestMigration < Test::Unit::TestCase

  def setup
    @valid_migration = '201101011615_up_this_is_a_test_migration.sql'
  end

  def teardown
  end

  def test_valid_filename_ok
    m = DBGeni::Migration.new('anydir', @valid_migration)
    assert_equal('this_is_a_test_migration', m.name)
    assert_equal('201101011615', m.sequence)
  end

  def test_invalid_filename_raises_exception
    # rubbish
    # missing part of the datestamp
    # missing up
    # missing title
    # no sql prefix
    invalid = %w(gfgffg 20110101000_up_title.sql 201101010000_title.sql 201101010000_up_.sql 201101010000_up_title)
    invalid.each do |f|
      assert_raises(DBGeni::MigrationFilenameInvalid) do
        m = DBGeni::Migration.new('anydir', f)
      end
    end
  end

end
