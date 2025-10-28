# config/application.rb
require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module ProjIter1
  class Application < Rails::Application
    config.load_defaults 7.1
    validates :url, presence: true, uniqueness: true
    validates :company, :title, presence: true

    before_create :seed_applied_history


    def push_status!(new_status)
      self.status = new_status
      self.history = (history || []) + [{ "status" => new_status, "ts" => Time.now.utc.iso8601 }]
      save!
    end

    private

    def seed_applied_history
      self.history ||= []
      self.history << { "status" => "Applied", "ts" => Time.now.utc.iso8601 }
    end
  end

end
