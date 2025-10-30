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

# HTTP
gem "httparty"
gem "nokogiri"

gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
gem "thruster", require: false

# Active Storage variants
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

# Windows time zone data
gem "tzinfo-data", platforms: %i[windows jruby]

# Auth
gem "bcrypt", "~> 3.1"

# Dev+Test tooling (shared)
group :development, :test do
  gem "rspec-rails", "~> 6.0"
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"

  # Security scanners
  gem "bundler-audit", require: false
  gem "brakeman", require: false

  # Linting
  gem "rubocop-rails-omakase", require: false
end

# Test-only stack
group :test do
  gem "cucumber", "~> 10.0"
  gem "cucumber-rails", require: false
  gem "capybara"
  gem "selenium-webdriver"
  gem "webmock", "~> 3.19", require: false
  gem "database_cleaner-active_record"
  gem "simplecov", require: false
end

# Dev convenience
group :development do
  gem "web-console"
end
