# app/models/application.rb
class Application < ApplicationRecord
  STATUSES = %w[Applied Bookmarked Interview Offer Rejected].freeze

  # ---------- Validations ----------
  validates :url, presence: true, uniqueness: true
  validates :company, :title, presence: true
  validates :status, inclusion: { in: STATUSES }, allow_nil: true

  # ---------- Normalization ----------
  before_validation :normalize_url

  # ---------- Defaults & callbacks ----------
  after_initialize :set_defaults, if: :new_record?
  before_create :seed_applied_history

  # ---------- Public API ----------
  def push_status!(new_status)
    raise ArgumentError, "invalid status: #{new_status}" unless STATUSES.include?(new_status)

    self.status  = new_status
    self.history = (history || []) + [{ "status" => new_status, "ts" => Time.now.utc.iso8601 }]
    save!
  end

  private

  def normalize_url
    self.url = url.to_s.strip.downcase
  end

  def set_defaults
    self.status  ||= "Applied"
    self.history ||= []
  end

  def seed_applied_history
    self.history ||= []
    self.history << { "status" => "Applied", "ts" => Time.now.utc.iso8601 }
  end
end
