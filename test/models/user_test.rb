# frozen_string_literal: true

require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "from_omniauth creates user" do
    auth = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "google-uid-new",
      info: { email: "new-user@example.com" }
    )

    assert_difference -> { User.count }, 1 do
      user = User.from_omniauth(auth)
      assert_equal "google-uid-new", user.google_uid
      assert_equal "new-user@example.com", user.email
    end
  end

  test "from_omniauth updates email for existing uid" do
    user = users(:one)
    auth = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: user.google_uid,
      info: { email: "updated@example.com" }
    )

    assert_no_difference -> { User.count } do
      record = User.from_omniauth(auth)
      assert_equal "updated@example.com", record.email
    end
  end
end
