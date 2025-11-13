require 'simplecov'
SimpleCov.command_name 'Cucumber'
SimpleCov.start 'rails'

require 'cucumber/rails'
require 'capybara'
require 'capybara/rails'
require 'selenium-webdriver'
require 'capybara/cucumber'
require 'webmock/cucumber'

Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  options.add_argument('--disable-gpu')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.default_driver = :selenium_chrome_headless
Capybara.javascript_driver = :selenium_chrome_headless

Capybara.server = :puma, { Silent: true }
Capybara.default_max_wait_time = 3

WebMock.disable_net_connect!(allow_localhost: true)

ActionController::Base.allow_rescue = false

begin
  DatabaseCleaner.strategy = :transaction
rescue NameError
  raise "You need to add database_cleaner to your Gemfile (in the :test group)"
end
Cucumber::Rails::Database.javascript_strategy = :truncation