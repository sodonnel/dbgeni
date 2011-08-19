require 'dbgeni/base'

require 'rbconfig'

module Kernel
  def self.is_windows?
    Config::CONFIG['host_os'] =~ /mswin|mingw/
  end
end
