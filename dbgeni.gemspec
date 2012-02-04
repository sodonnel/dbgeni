Gem::Specification.new do |s| 
  s.name = "dbgeni"
  s.version = "0.5.0"
  s.author = "Stephen O'Donnell"
  s.email = "stephen@betteratoracle.com"
  s.homepage = "http://dbgeni.com"
  s.platform = Gem::Platform::RUBY
  s.summary = "A generic database installer"
  s.files = (Dir.glob("{bin,lib}/**/*") + Dir.glob("[A-Z]*")).reject{ |fn| fn.include? "temp" }

  s.require_path = "lib"
  s.bindir       = "bin"
  s.executables << 'dbgeni'	
  s.description  = "Generic installer to manage database migrations for various databases"
#  s.autorequire = "name"
#  s.test_files = FileList["{test}/**/*test.rb"].to_a
  s.has_rdoc = false
#  s.extra_rdoc_files = ["README"]
#  s.add_dependency("dependency", ">= 0.x.x")
end