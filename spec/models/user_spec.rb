require 'rails_helper'

RSpec.describe User, type: :model do
  it "is invalid without an email" do
    # Even without a username, it should be invalid due to missing email
    user = User.new(email: nil)
    expect(user).not_to be_valid
  end

  it "is valid with a proper email" do
    # Added username to make the user valid
    user = User.new(username: "testuser", email: "test@example.com", password: "password")
    expect(user).to be_valid
  end
end
