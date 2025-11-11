
require 'simplecov'
SimpleCov.command_name 'Cucumber'
SimpleCov.start 'rails' do
  add_filter '/spec/'
  add_filter '/config/'
  add_filter '/vendor/'
end

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

Before do |scenario|
 
  if scenario.tags.any? { |tag| tag.name == '@javascript' }
    DatabaseCleaner.strategy = :truncation
  else
    DatabaseCleaner.strategy = :transaction
  end
  DatabaseCleaner.start
end

After do
  ActiveRecord::Base.logger.silence do
    DatabaseCleaner.clean
  end
end

After do
  Capybara.reset_sessions!
end