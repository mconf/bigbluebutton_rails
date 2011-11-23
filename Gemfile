source 'http://rubygems.org'

gemspec

gem 'bigbluebutton-api-ruby', '~> 0.1.0.rc1'

group :development, :test do
  gem "rspec-rails"
  gem "factory_girl"
  gem "sqlite3-ruby"
  gem "generator_spec"
  gem "shoulda-matchers"
  gem "forgery"
  gem "cucumber-rails"
  gem "database_cleaner"
  gem "rdoc"
  gem "rails_best_practices"
end

group :test do
  if RUBY_VERSION >= "1.9"
    gem 'simplecov', '>= 0.4.0', :require => false
  end
end
