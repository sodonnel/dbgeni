$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$:.unshift File.expand_path(File.dirname(__FILE__))

require 'helper'
require "dbgeni"
require 'test/unit'

class TestLogger < Test::Unit::TestCase

  include TestHelper

  def setup
  end

  def teardown
  end

  def test_logger_instance_created
    assert_nothing_raised do
      instance = DBGeni::Logger.instance(TestHelper::TEMP_DIR)
      instance.close
    end
  end

  def test_only_one_instance_of_logger_created
    instance_one = DBGeni::Logger.instance(TestHelper::TEMP_DIR)
    instance_two = DBGeni::Logger.instance(TestHelper::TEMP_DIR)
    assert_equal(instance_one, instance_two)
    instance_one.close
  end

  def test_logger_can_be_closed
    instance = DBGeni::Logger.instance(TestHelper::TEMP_DIR)
    assert_nothing_raised do
      instance.close
    end
  end

  def test_logger_can_be_closed_and_new_instance_when_opened_again
    instance = DBGeni::Logger.instance(TestHelper::TEMP_DIR)
    instance.close
    instance_two = DBGeni::Logger.instance(TestHelper::TEMP_DIR)
    assert_not_equal(instance, instance_two)
  end

  def test_no_exception_raised_when_no_log_location
    assert_nothing_raised DBGeni::NoLoggerLocation do
      instance = DBGeni::Logger.instance
    end
  end

  def test_logger_returns_detailed_dir
    instance = DBGeni::Logger.instance(TestHelper::TEMP_DIR)
    assert_not_nil(instance.detailed_log_dir)
  end

  def test_logger_creates_detailed_dir
    instance = DBGeni::Logger.instance(TestHelper::TEMP_DIR)
    assert_not_nil(instance.detailed_log_dir)
    assert_equal(true, File.exists?(instance.detailed_log_dir))
  end

  def test_detailed_dir_can_be_rese
    instance = DBGeni::Logger.instance(TestHelper::TEMP_DIR)
    old_dir = instance.detailed_log_dir
    sleep(2)
    instance.reset_detailed_log_dir
    assert_not_equal(old_dir, instance.detailed_log_dir)
  end


end
