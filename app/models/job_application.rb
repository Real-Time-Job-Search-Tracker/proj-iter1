class JobApplication < ApplicationRecord
  self.table_name = "job_applications"

  belongs_to :user, optional: true

  validates :url,
            presence: true,
            uniqueness: { scope: :user_id }
  validates :company, :title, presence: true

  before_create do
    self.status     ||= "Applied"
    self.history    ||= []
    self.history    << { "status" => "Applied", "ts" => Time.now.utc.iso8601 }
    self.applied_on ||= Date.today
  end

  def push_status!(new_status)
    update!(
      status: new_status,
      history: (history || []) + [
        { "status" => new_status, "ts" => Time.now.utc.iso8601 }
      ]
    )
  end
end
