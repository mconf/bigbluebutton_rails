source "http://rubygems.org"

gemspec

gem 'mysql2'
gem "jquery-rails"
gem "forgery"

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
  gem "factory_girl"
  gem "generator_spec"
  gem "rspec-rails", '~> 2.99.0'
  gem 'rspec-activemodel-mocks'
  # gem "bbbot-ruby", :git => "git://github.com/mconf/bbbot-ruby.git"
  gem "capybara", "~> 2.2.0"
  gem "capybara-mechanize" # for remote requests
  gem "capybara-webkit" # best option found for js
  gem "launchy"
  gem "webmock"

  # to use redis in-memory and clean it in-between tests, used for resque
  gem "fakeredis", :require => "fakeredis/rspec"
end

# Gems used by the test application
group :assets do
  gem 'sass-rails', '~> 4.0.0'
  gem 'coffee-rails', '~> 4.0.0'
  gem 'therubyracer', '~> 0.12.0'
  gem 'uglifier', '>= 1.0.3'
end
