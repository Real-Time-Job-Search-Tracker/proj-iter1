source "https://rubygems.org"

# Framework
gem "rails", "~> 8.1.0"
gem "puma", ">= 5.0"
gem "propshaft"

# JS (Importmap + Hotwire)
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"

# JSON helpers (optional but handy)
gem "jbuilder"

# HTTP / HTML parsing (your JobsController uses these)
gem "httparty"
gem "nokogiri"

gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
gem "thruster", require: false

# Active Storage variants (OK to keep even if unused yet)
gem "image_processing", "~> 1.2"

# Database adapters
group :development, :test do
  gem "sqlite3", "~> 2.1"
end

group :production do
  gem "pg", "~> 1.1"
end

# Boot speed
gem "bootsnap", require: false

# Windows time zone data (safe to keep)
gem "tzinfo-data", platforms: %i[windows jruby]

# Authentication (used by User model)
gem "bcrypt", "~> 3.1"

# RSpec for unit/model/request tests
group :development, :test do
  gem "rspec-rails", "~> 6.0"
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"

  # Security scanners used in your CI
  gem "bundler-audit", require: false
  gem "brakeman", require: false

  # Linting (used by your CI RuboCop job)
  gem "rubocop-rails-omakase", require: false
end

# Cucumber + system test stack
group :test do
  gem "cucumber", "~> 10.0"
  gem "cucumber-rails", require: false
  gem "capybara"
  gem "selenium-webdriver"
  gem "webmock", "~> 3.0"
  gem "database_cleaner-active_record"
  gem "simplecov", require: false
end

# Dev convenience
group :development do
  gem "web-console"
end
