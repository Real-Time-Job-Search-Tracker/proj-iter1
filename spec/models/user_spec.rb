require 'rails_helper'

RSpec.describe User, type: :model do
  it "is invalid without an email" do
    user = User.new(email: nil)
    expect(user).not_to be_valid
  end

  it "is valid with a proper email" do
    user = User.new(email: "test@example.com", password: "password")
    expect(user).to be_valid
  end
end
