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

  def self.executable_exists?(cmd)
    exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
    ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
      exts.each { |ext|
        exe = "#{path}/#{cmd}#{ext}"
        return exe if File.executable? exe
      }
    end
    return nil
  end

end

if RUBY_PLATFORM == 'java'
  require 'rubygems'
  require 'java'

  if Config::CONFIG['ruby_version'] =~ /1\.8/
    raise "DBGeni requires the --1.9 switch to be passed to jruby (or set env variable JRUBY_OPTS=--1.9)"
  end

  module JavaLang
    include_package "java.lang"
  end

  module JavaSql
    include_package 'java.sql'
  end
end

require 'dbgeni/base'
