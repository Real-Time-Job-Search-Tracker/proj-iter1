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

  # Validations
  validates :username,
            presence: true,
            uniqueness: { case_sensitive: false }

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
end
