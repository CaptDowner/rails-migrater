# encoding: UTF-8
#require 'rubygems'
require 'bundler'
require "bundler/gem_tasks"

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "rails-migrater"
  gem.homepage = "http://github.com/CaptDowner/rails-migrater"
  gem.license = "MIT"
  gem.summary = %Q{Utility to query a MySQL database and write a schema file for rails.}
  gem.description = %Q{Utility to query a MySQL database and return a schema file for use with rails. Run this gem from a rails project root directory: rails-migrater -s [server] -u [username] -p [password] -d [database]

This will write a file in the %rails_root%/db directory, and will be named: [YYYYMMDDhhmmss]_[database name]_schema.rb

This file can then be used to migrate an existing database to rails.
}
  gem.email = "captdowner@comcast.net"
  gem.authors = ["Steve Downie"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs.push "lib"
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
end

#require 'cucumber/rake/task'
#Cucumber::Rake::Task.new(:features)

#task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "rails-migrater #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
