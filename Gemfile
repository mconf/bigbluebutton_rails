source "http://rubygems.org"

gemspec

group :development do
  gem "sqlite3-ruby"
  gem "forgery"
  gem "rdoc"
  gem "rails_best_practices"
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

  gem "capybara-mechanize" # for remote requests
  gem "launchy"
  gem "capybara-webkit" # best option found for js
end
