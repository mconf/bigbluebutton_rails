source "http://rubygems.org"

gemspec

gem 'rails', '~> 5.0.7'

gem 'mysql2'
gem "jquery-rails"
gem "forgery"
gem 'rabl'
gem 'activerecord-import'
gem 'byebug'
gem 'responders', '~> 2.0'

group :development do
  gem "rdoc"
  gem "rails_best_practices"
end

group :test do
  if RUBY_VERSION >= "1.9"
    gem "simplecov", ">= 0.4.0", :require => false
  end

  gem 'minitest'
  gem "cucumber-rails", :require => false
  gem "database_cleaner"
  gem 'shoulda-matchers', '~> 2.6.1'
  gem 'factory_bot_rails'
  gem "generator_spec"
  gem "rspec-rails", '~> 3.9'
  gem 'rspec-activemodel-mocks'
  gem 'rails-controller-testing'
  # gem "bbbot-ruby", :git => "git://github.com/mconf/bbbot-ruby.git"
  gem "capybara", "~> 2.2.0"
  gem "capybara-mechanize" # for remote requests
  gem "capybara-webkit" # best option found for js
  gem "launchy"
  gem "webmock"
  gem "timecop"

  # to use redis in-memory and clean it in-between tests, used for resque
  gem 'fakeredis', '0.7.0', require: "fakeredis/rspec"
  gem 'redis', '4.8.0'
  gem 'redis-namespace', '~> 1.9.0'
end

# Gems used by the test application
group :assets do
  gem 'sass-rails', '5.0.7'
  gem 'coffee-rails', '~> 4.2.2'
  gem 'mini_racer', '~> 0.4.0'
  gem 'uglifier', '>= 1.0.3'
end
