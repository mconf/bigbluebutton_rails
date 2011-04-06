require 'rubygems'
require 'bundler/setup'
require 'rake/rdoctask'
require 'rspec/core/rake_task'
require 'rake/gempackagetask'

desc 'Default: run tests.'
task :default => :spec

RSpec::Core::RakeTask.new(:spec)

desc 'Generate documentation.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'BigBlueButton on Rails'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('CHANGELOG.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

eval("$specification = begin; #{ IO.read('bigbluebutton_rails.gemspec')}; end")
Rake::GemPackageTask.new $specification do |pkg|
  pkg.need_tar = true
  pkg.need_zip = true
end

desc 'Setup RailsApp used in tests.'
namespace "setup" do
  task :rails_app do |app|
    cd 'spec/rails_app/'
    sh "rake db:drop ENV=test"
    sh "rails destroy bigbluebutton_rails:install"
    sh "rails generate bigbluebutton_rails:install"
    sh "rake db:migrate ENV=test"
    sh "rake db:test:prepare"
  end
end
