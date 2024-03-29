# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "migrater/version"

Gem::Specification.new do |s|
  s.name        = "rails-migrater"
  s.version     = Migrater::VERSION
  s.authors     = ["CaptDowner"]
  s.email       = ["captdowner@comcast.net"]
  s.homepage    = ""
  s.summary     = %q{rails-migrater is a gem for extracting MySQL database tables.}
  s.description = %q{rails-migrater extracts database table information and writes 
                     all of the table information out to a file called 
                     "[YYYYMMDDhhmmss_[databasename]_schema.rb". Once written, this file 
                     can be used in Rails to read and write to an existing database. 
                     You need to know the specific database name, and know a valid 
                     use and password with read/write access to this database. }

  s.rubyforge_project = "rails-migrater"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]


  # specify any dependencies here; for example:
  s.add_dependency "mysql2", "~> 0.3.11"
  s.add_dependency "enum_column3", "~> 0.1.3" 
  s.add_development_dependency "rspec", "~> 2.8.0"
  s.add_development_dependency  "cucumber", ">= 0"
  s.add_development_dependency  "bundler", "~> 1.0.0"
  s.add_development_dependency  "jeweler", "~> 1.6.4"
  s.add_development_dependency  "rcov", ">= 0"
  
  # s.add_runtime_dependency "rest-client"
end
