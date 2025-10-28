require 'simplecov'
SimpleCov.command_name 'Cucumber'
SimpleCov.start 'rails'

require 'cucumber/rails'
require 'capybara'
require 'capybara/rails'
require 'selenium-webdriver'
require 'webmock/cucumber'

ActionController::Base.allow_rescue = false

Capybara.server = :puma, { Silent: true }
Capybara.javascript_driver = :selenium_chrome_headless
Capybara.default_max_wait_time = 3
WebMock.disable_net_connect!(allow_localhost: true)

begin
  DatabaseCleaner.strategy = :transaction
rescue NameError
  raise "You need to add database_cleaner to your Gemfile (in the :test group) if you wish to use it."
end

Cucumber::Rails::Database.javascript_strategy = :truncation