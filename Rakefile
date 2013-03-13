require 'rubygems'
require 'bundler/setup'
require 'rdoc/task'
require 'rspec/core/rake_task'
require 'rubygems/package_task'
require 'cucumber'
require 'cucumber/rake/task'

desc 'Default: run specs and features.'
task :default => [:spec, :cucumber]

RSpec::Core::RakeTask.new(:spec)

desc 'Generate documentation.'
RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'BigBlueButton on Rails'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('CHANGELOG.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
  rdoc.rdoc_files.include('app/**/*.rb')
end

eval("$specification = begin; #{ IO.read('bigbluebutton_rails.gemspec')}; end")
Gem::PackageTask.new $specification do |pkg|
  pkg.need_tar = true
  pkg.need_zip = true
end

namespace :rails_app do
  desc 'Setup rails app used in tests.'
  task :install do |app|
    cd File.join(File.dirname(__FILE__), "spec", "rails_app")
    sh "rails destroy bigbluebutton_rails:install"
    sh "rails generate bigbluebutton_rails:install"
    cd File.dirname(__FILE__)
  end

  desc 'Setup the db in the rails app used in tests.'
  task :db do
    cd File.join(File.dirname(__FILE__), "spec", "rails_app")
    # base
    sh "rake db:drop:all"
    sh "rake db:create:all"
    # development
    sh "rake db:migrate RAILS_ENV=development"
    sh "rake db:seed RAILS_ENV=development"
    # test
    sh "rake db:migrate RAILS_ENV=test"
    sh "rake db:test:prepare RAILS_ENV=test"
    cd File.dirname(__FILE__)
  end

  desc 'Populate the db in the test app'
  task :populate do
    cd "spec/rails_app/"
    sh "rake db:populate"
    cd "../.."
  end

  namespace :recordings do
    desc 'Updates the recordings'
    task :update do
      cd "spec/rails_app/"
      sh "rake bigbluebutton_rails:recordings:update"
      cd "../.."
    end
  end
end

task :cucumber do
  if File.exists? "features/"
    puts "* Gem features"
    sh "cucumber features/"
  end

  puts "* Dummy app features"
  cd File.join(File.dirname(__FILE__), "spec", "rails_app")
  sh "cucumber features/"
  cd File.dirname(__FILE__)
end

task :notes do
  puts `grep -r 'OPTIMIZE\\|FIXME\\|TODO' app/ public/ spec/`
end

desc 'Setup the rails_app using the migration files created when upgrading the gem
      version, run all tests and destroys the generated files.'
namespace :spec do
  task :migrations do |app|
    cd "spec/rails_app/"
    sh "rails destroy bigbluebutton_rails:install"
    sh "rails generate bigbluebutton_rails:install 0.0.4"
    sh "rails generate bigbluebutton_rails:install 0.0.5 --migration-only"

    sh "rake db:drop RAILS_ENV=test"
    sh "rake db:create RAILS_ENV=test"
    sh "rake db:migrate RAILS_ENV=test"
    sh "rake db:test:prepare RAILS_ENV=test"

    cd "../.."
    Rake::Task["spec"].invoke
    Rake::Task["cucumber"].invoke

    cd "spec/rails_app/"
    sh "rails destroy bigbluebutton_rails:install 0.0.5 --migration-only"
    sh "rails destroy bigbluebutton_rails:install 0.0.4"
  end
end

desc 'Generate the best practices report'
task :best_practices do |app|
  sh "rails_best_practices -f html --spec &>/dev/null"
  puts
  puts "Output will be in the file rails_best_practices_output.html"
  puts
end
