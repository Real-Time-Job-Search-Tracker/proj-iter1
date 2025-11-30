# app/models/user.rb
class User < ApplicationRecord
  has_secure_password

  has_one_attached :avatar

  STUDENT_TRACKS = [
    "Computer Science",
    "Machine Learning / AI",
    "Data Science",
    "Business Analytics",
    "Finance / Quant",
    "Electrical Engineering",
    "Software Engineering Bootcamp",
    "Product Management",
    "UI/UX Design",
    "Other"
  ].freeze

  JOB_TITLES = [
    "Software Engineer",
    "Machine Learning Engineer",
    "Data Scientist",
    "Quant Researcher",
    "Backend Engineer",
    "Frontend Engineer",
    "Fullstack Engineer",
    "Product Manager",
    "UI/UX Designer",
    "Other"
  ].freeze
  # Associations
  has_many :job_applications, dependent: :destroy

  # Callbacks
  before_validation :normalize_fields

  # After successful registration, the method for generating sample data will be automatically executed
  after_create :seed_example_data

  # Validations
  validates :username, presence: true, uniqueness: { case_sensitive: false }
  
  validates :email,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :password,
            length: { minimum: 6 },
            if: -> { password.present? }

  private

  def normalize_fields
    self.email    = email.to_s.strip.downcase
    self.username = username.to_s.strip
  end

  # Logic for generating sample data
  def seed_example_data
    # Example 1
    self.job_applications.create!(
      company: "Tech Example Inc. (Example)",
      title: "Software Engineer",
      url: "https://example.com/demo-job-1",
      status: "Applied",
      applied_on: Date.today,
      history: [
        { "status" => "Applied", "changed_at" => Time.now }
      ]
    )

    # Example 2
    self.job_applications.create!(
      company: "Dream Corp (Example)",
      title: "Product Manager",
      url: "https://example.com/demo-job-2",
      status: "Offer",
      applied_on: 2.weeks.ago,
      history: [
        { "status" => "Applied", "changed_at" => 2.weeks.ago },
        { "status" => "Round1", "changed_at" => 10.days.ago },
        { "status" => "Interview", "changed_at" => 5.days.ago },
        { "status" => "Offer", "changed_at" => 1.day.ago }
      ]
    )
  end
end
