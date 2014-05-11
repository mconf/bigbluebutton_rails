source "http://rubygems.org"

gemspec

gem "strong_parameters"
gem "resque"
gem "browser"

group :development do
  gem "forgery"
  gem "rdoc"
  gem "rails_best_practices"
  gem "spork-rails"
end

group :test do
  if RUBY_VERSION >= "1.9"
    gem "simplecov", ">= 0.4.0", :require => false
  end

  gem "cucumber-rails", :require => false
  gem "database_cleaner"
  gem "shoulda-matchers"
  gem "factory_girl"
  gem "generator_spec"
  gem "rspec-rails"
  gem "bbbot-ruby", :git => "git://github.com/mconf/bbbot-ruby.git"

  # to use redis in-memory and clean it in-between tests, used for resque
  gem "fakeredis", :require => "fakeredis/rspec"

  gem "capybara", "~> 2.0.0"
  gem "capybara-mechanize", "~> 1.0.0" # for remote requests
  gem "capybara-webkit" # best option found for js
  gem "launchy"
end

# Gems used by the test application
group :assets do
  gem 'sass-rails', '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'therubyracer', '~> 0.12.0'
  gem 'uglifier', '>= 1.0.3'
end
group :development do
  gem 'mysql2'
  gem "jquery-rails"
  gem "whenever"
end
