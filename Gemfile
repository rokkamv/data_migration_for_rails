source 'https://rubygems.org'

ruby '3.0.0'

# Core Rails
gem 'rails', '~> 7.1.5', '>= 7.1.5.2'

# Database
gem 'mysql2', '~> 0.5'
gem 'pg'

# Web server
gem 'puma', '>= 5.0'

# Asset pipeline
gem 'importmap-rails'
gem 'sprockets-rails'
gem 'stimulus-rails'
gem 'turbo-rails'

# Views
gem 'jbuilder'

# Authentication & Authorization
gem 'bcrypt', '~> 3.1.7'
gem 'devise'
gem 'pundit'

# Background jobs
gem 'redis', '>= 4.0.1'
gem 'sidekiq'

# File storage
gem 'aws-sdk-s3', require: false

# File handling
gem 'rubyzip'

# Configuration
gem 'dotenv-rails'

# Performance
gem 'bootsnap', require: false

# Platform specific
gem 'tzinfo-data', platforms: %i[mswin mswin64 mingw x64_mingw jruby]

group :development, :test do
  gem 'debug', platforms: %i[mri mswin mswin64 mingw x64_mingw]
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'rspec-rails'
end

group :development do
  gem 'web-console'
end

group :test do
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'shoulda-matchers'
end
