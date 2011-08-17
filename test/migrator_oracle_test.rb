$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$:.unshift File.expand_path(File.dirname(__FILE__))

require 'helper'

require "dbgeni"
require 'test/unit'
require 'dbgeni/migrators/oracle'

class TestMigratorOracle < Test::Unit::TestCase

  include TestHelper

  def setup
  end

  def teardown
  end

end
