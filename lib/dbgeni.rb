require 'rbconfig'
require 'digest/sha1'

module Kernel

  def self.is_windows?
    Config::CONFIG['host_os'] =~ /mswin|mingw/
  end

  def suppress_warnings
    original_verbosity = $VERBOSE
    $VERBOSE = nil
    result = yield
    $VERBOSE = original_verbosity
    return result
  end

end

require 'dbgeni/base'
