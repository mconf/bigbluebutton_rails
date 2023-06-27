require 'rubygems'
require 'bundler/setup'
require 'rdoc/task'
require 'rspec/core/rake_task'
require 'rubygems/package_task'
require 'cucumber'
require 'cucumber/rake/task'

desc 'Default: run specs and features.'
task :default => [:spec]

RSpec::Core::RakeTask.new(:spec)

desc 'Generate documentation.'
RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'BigBlueButton on Rails'
  rdoc.rdoc_files.include('README.md')
  rdoc.rdoc_files.include('CHANGELOG.md')
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
    sh "bundle exec rails destroy bigbluebutton_rails:install"
    sh "bundle exec rails generate bigbluebutton_rails:install"
    cd File.dirname(__FILE__)
  end

  desc 'Setup the db in the rails app used in tests.'
  task :db do
    cd File.join(File.dirname(__FILE__), "spec", "rails_app")
    sh "bundle exec rake db:drop db:create db:migrate db:seed"
    cd File.dirname(__FILE__)
  end

  desc 'Populate the db in the test app'
  task :populate do
    cd "spec/rails_app/"
    sh "bundle exec rake db:populate"
    cd "../.."
  end

  namespace :recordings do
    desc 'Updates the recordings'
    task :update do
      cd "spec/rails_app/"
      sh "bundle exec rake bigbluebutton_rails:recordings:update"
      cd "../.."
    end
  end
end

task :cucumber do
  # Disable all features that need the bot. It isn't working since BigBlueButton 0.81.
  tags = "~@need-bot"

  puts "* Dummy app features"
  cd File.join(File.dirname(__FILE__), "spec", "rails_app")
  sh "bundle exec cucumber features/ --tags #{tags}"
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
    sh "bundle exec rails destroy bigbluebutton_rails:install"
    sh "bundle exec rails generate bigbluebutton_rails:install 0.0.4"
    sh "bundle exec rails generate bigbluebutton_rails:install 0.0.5 --migration-only --force"
    sh "bundle exec rails generate bigbluebutton_rails:install 1.3.0 --migration-only --force"
    sh "bundle exec rails generate bigbluebutton_rails:install 1.4.0 --migration-only --force"
    sh "bundle exec rails generate bigbluebutton_rails:install 2.0.0 --migration-only --force"
    sh "bundle exec rails generate bigbluebutton_rails:install 2.1.0 --migration-only --force"
    sh "bundle exec rails generate bigbluebutton_rails:install 2.2.0 --migration-only --force"
    sh "bundle exec rails generate bigbluebutton_rails:install 2.3.0 --migration-only --force"
    sh "bundle exec rails generate bigbluebutton_rails:install 2.3.1 --migration-only --force"
    sh "bundle exec rails generate bigbluebutton_rails:install 3.0.0 --migration-only --force"
    sh "bundle exec rails generate bigbluebutton_rails:install 3.0.1 --migration-only --force"
    sh "bundle exec rails generate bigbluebutton_rails:install 3.1.0 --migration-only --force"
    sh "bundle exec rails generate bigbluebutton_rails:install 3.6.0 --migration-only --force"

    sh "bundle exec rake db:drop RAILS_ENV=test"
    sh "bundle exec rake db:create RAILS_ENV=test"
    sh "bundle exec rake db:migrate RAILS_ENV=test"
    sh "bundle exec rake db:seed RAILS_ENV=test"

    cd "../.."
    Rake::Task["spec"].invoke
    # Rake::Task["cucumber"].invoke

    cd "spec/rails_app/"
    sh "bundle exec rails destroy bigbluebutton_rails:install 3.6.0 --migration-only"
    sh "bundle exec rails destroy bigbluebutton_rails:install 3.1.0 --migration-only"
    sh "bundle exec rails destroy bigbluebutton_rails:install 3.0.1 --migration-only"
    sh "bundle exec rails destroy bigbluebutton_rails:install 3.0.0 --migration-only"
    sh "bundle exec rails destroy bigbluebutton_rails:install 2.3.1 --migration-only"
    sh "bundle exec rails destroy bigbluebutton_rails:install 2.3.0 --migration-only"
    sh "bundle exec rails destroy bigbluebutton_rails:install 2.2.0 --migration-only"
    sh "bundle exec rails destroy bigbluebutton_rails:install 2.1.0 --migration-only"
    sh "bundle exec rails destroy bigbluebutton_rails:install 2.0.0 --migration-only"
    sh "bundle exec rails destroy bigbluebutton_rails:install 1.4.0 --migration-only"
    sh "bundle exec rails destroy bigbluebutton_rails:install 1.3.0 --migration-only"
    sh "bundle exec rails destroy bigbluebutton_rails:install 0.0.5 --migration-only"
    sh "bundle exec rails destroy bigbluebutton_rails:install 0.0.4"
  end
end

desc 'Generate the best practices report'
task :best_practices do |app|
  sh "bundle exec rails_best_practices -f html --spec &>/dev/null"
  puts
  puts "Output will be in the file rails_best_practices_output.html"
  puts
end
