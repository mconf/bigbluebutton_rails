$:.push File.expand_path("../lib", __FILE__)
require "bigbluebutton_rails/version"

Gem::Specification.new do |s|
  s.name        = "bigbluebutton_rails"
  s.version     = BigbluebuttonRails::VERSION.dup
  s.platform    = Gem::Platform::RUBY
  s.summary     = "BigBlueButton integration for Ruby on Rails"
  s.email       = "mconf@googlegroups.com"
  s.homepage    = "http://github.com/mconf/bigbluebutton_rails"
  s.description = "It allows you to interact with a BigBlueButton server from your Ruby on Rails web application"
  s.authors     = ['Leonardo Crauss Daronco']

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ["lib"]

  s.add_runtime_dependency("rails", "~> 3.0.3")
  s.add_runtime_dependency("bigbluebutton-api-ruby", "~> 0.0.10")

  s.add_development_dependency("rspec-rails", "~> 2.5.0")
  s.add_development_dependency("factory_girl", "~> 1.3.2")
  s.add_development_dependency("sqlite3-ruby", "~> 1.3.3")
  s.add_development_dependency("generator_spec", "~> 0.8.2")
  s.add_development_dependency("shoulda-matchers", "~> 1.0.0.beta")
  s.add_development_dependency("forgery", "~> 0.3.7")
end