# class User < ApplicationRecord
#   has_secure_password

#   validates :username, presence: true, uniqueness: true


#   validates :email,
#             presence: true,
#             uniqueness: { case_sensitive: false },
#             format: { with: URI::MailTo::EMAIL_REGEXP }


#   validates :password, length: { minimum: 6 }, if: -> { password.present? }
# end



# class User < ApplicationRecord
#   has_secure_password

#   has_many :job_applications, dependent: :destroy

#   validates :username, presence: true, uniqueness: true

#   validates :email,
#             presence: true,
#             uniqueness: { case_sensitive: false },
#             format: { with: URI::MailTo::EMAIL_REGEXP }

#   validates :password, length: { minimum: 6 }, if: -> { password.present? }
# end

# class User < ApplicationRecord
#   has_secure_password

#   # ➜ 一定要加这一行
#   has_many :job_applications, dependent: :destroy

#   validates :username, presence: true, uniqueness: true

#   validates :email,
#             presence: true,
#             uniqueness: { case_sensitive: false },
#             format: { with: URI::MailTo::EMAIL_REGEXP }

#   validates :password, length: { minimum: 6 }, if: -> { password.present? }
# end



# app/models/user.rb
class User < ApplicationRecord
  has_secure_password

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
