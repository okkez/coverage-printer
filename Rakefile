require 'rubygems'
require 'bundler'
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
  gem.name = "coverage-printer"
  gem.homepage = "http://github.com/okkez/coverage-printer"
  gem.license = "MIT"
  gem.summary = %Q{This library provides the ability to visualize code coverage for Ruby1.9.}
  gem.description = %Q{This library provides the ability to visualize code coverage for Ruby1.9.}
  gem.email = "okkez000@gmail.com"
  gem.authors = ["okkez"]
  # Include your dependencies below. Runtime dependencies are required when using your gem,
  # and development dependencies are only needed for development (ie running rake tasks, tests, etc)
  #  gem.add_runtime_dependency 'jabber4r', '> 0.1'
  #  gem.add_development_dependency 'rspec', '> 1.2.3'
  gem.required_ruby_version = Gem::Requirement.new(">= 1.9.1")
end
Jeweler::RubygemsDotOrgTasks.new
