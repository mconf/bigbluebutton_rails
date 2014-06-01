$:.push File.expand_path("../lib", __FILE__)
require "bigbluebutton_rails/version"

Gem::Specification.new do |s|
  s.name        = "bigbluebutton_rails"
  s.version     = BigbluebuttonRails::VERSION.dup
  s.platform    = Gem::Platform::RUBY
  s.summary     = "BigBlueButton integration for Ruby on Rails"
  s.email       = "mconf-dev@googlegroups.com"
  s.homepage    = "http://github.com/mconf/bigbluebutton_rails"
  s.description = "It allows you to interact with BigBlueButton from your Ruby on Rails application"
  s.authors     = ['Mconf', 'Leonardo Crauss Daronco']
  s.license     = 'MIT'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ["lib"]

  s.add_dependency("rails", ">= 3.0.0")
  s.add_dependency("bigbluebutton-api-ruby", "~> 1.3.0")
  s.add_dependency("strong_parameters", "~> 0.2.0")
  s.add_dependency("resque", "~> 1.25.1")
  s.add_dependency("browser", "~> 0.5.0")
end
