class User < ApplicationRecord
  has_secure_password

  validates :username, presence: true, uniqueness: true


  validates :email,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }


  validates :password, length: { minimum: 6 }, if: -> { password.present? }
end
