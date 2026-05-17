# frozen_string_literal: true

require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "login page renders" do
    get login_path
    assert_response :success
    assert_includes response.body, "記帳"
    assert_includes response.body, "登入"
    if GoogleOauth.configured?
      assert_includes response.body, "使用 Google 登入"
      assert_includes response.body, "/auth/google_oauth2"
    end
  end

  test "trial login sets session in test" do
    post trial_login_path
    assert_redirected_to root_path
    follow_redirect!
    assert_response :success
  end

  test "logout clears session" do
    post trial_login_path
    delete logout_path
    assert_redirected_to login_path
  end
end
