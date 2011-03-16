$:.push File.expand_path("../lib", __FILE__)
require "bigbluebutton-rails/version"

Gem::Specification.new do |s|
  s.name        = "bigbluebutton-rails"
  s.version     = BigBlueButtonRails::VERSION.dup
  s.platform    = Gem::Platform::RUBY  
  s.summary     = "BigBlueButton integration for Ruby on Rails"
  s.email       = "mconf@googlegroups.com"
  s.homepage    = "http://github.com/mconf/bigbluebutton-rails"
  s.description = "BigBlueButton integration for Ruby on Rails"
  s.authors     = ['Leonardo Crauss Daronco']

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency("bigbluebutton-api-ruby", "~> 0.0.4")
end