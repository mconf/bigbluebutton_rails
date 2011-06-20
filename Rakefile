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

desc 'Setup RailsApp used in tests.'
namespace :setup do
  task :rails_app do |app|
    cd "spec/rails_app/"
    sh "rails destroy bigbluebutton_rails:install"
    sh "rails generate bigbluebutton_rails:install"
  end

  namespace :rails_app do |app|
    task :db do
      # base
      cd "spec/rails_app/"
      sh "rake db:drop:all"
      sh "rake db:create:all"
      # test
      sh "rake db:migrate RAILS_ENV=test"
      sh "rake db:test:prepare RAILS_ENV=test"
      # development
      sh "rake db:migrate RAILS_ENV=development"
      sh "rake db:seed RAILS_ENV=development"
    end
  end
end

task :cucumber do
  if File.exists? "features/"
    puts "* Gem features"
    sh %{ cucumber features/ }
  end
  puts "* Dummy app features"
  sh %{ cd spec/rails_app; cucumber features/ }
end

task :notes do
  puts `grep -r 'OPTIMIZE\\|FIXME\\|TODO' app/ public/ spec/`
end

# FIXME: not the best way to test these migrations, but works for now
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
