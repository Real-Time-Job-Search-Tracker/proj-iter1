# 覆盖率统计
require 'simplecov'
SimpleCov.command_name 'Cucumber'
SimpleCov.start 'rails'

# 基础库
require 'cucumber/rails'
require 'capybara/rails'
require 'capybara/cucumber'
require 'selenium-webdriver'
require 'webmock/cucumber'

# 注册 headless chrome 驱动，用于 JS 场景
Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  options.add_argument('--disable-gpu')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

# 默认使用 rack_test（适合 API 场景）
Capybara.default_driver = :rack_test

# JS 场景标签映射到 selenium_chrome_headless
Capybara.javascript_driver = :selenium_chrome_headless

# 使用 Puma 提升性能
Capybara.server = :puma, { Silent: true }
Capybara.default_max_wait_time = 3

# WebMock：允许本地连接
WebMock.disable_net_connect!(allow_localhost: true)

# 控制器错误直接抛出
ActionController::Base.allow_rescue = false

# 数据清理策略统一用 truncation（保证 JS/非JS 场景隔离）
begin
  require 'database_cleaner/active_record'
  DatabaseCleaner.strategy = :truncation
rescue LoadError
  raise "Please add `database_cleaner-active_record` to Gemfile in :test group"
end
Cucumber::Rails::Database.javascript_strategy = :truncation

# 在每个场景前重置浏览器 session
Before do
  Capybara.reset_sessions!
end
