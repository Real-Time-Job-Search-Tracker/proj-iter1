class JobApplication < ApplicationRecord
  validates :url, presence: true, uniqueness: true
  validates :company, :title, presence: true

  before_create do
    self.status  ||= "Applied"
    self.history ||= []
    self.history << { "status" => "Applied", "ts" => Time.now.utc.iso8601 }
  end

  def push_status!(new_status)
    update!(
      status: new_status,
      history: (history || []) + [{ "status" => new_status, "ts" => Time.now.utc.iso8601 }]
    )
  end
end
