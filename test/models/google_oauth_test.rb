# frozen_string_literal: true

require "test_helper"

class GoogleOauthTest < ActiveSupport::TestCase
  test "normalize_host strips scheme and path" do
    assert_equal "myapp.up.railway.app", GoogleOauth.normalize_host("https://myapp.up.railway.app/")
    assert_equal "myapp.up.railway.app", GoogleOauth.normalize_host("http://myapp.up.railway.app/foo")
  end

  test "redirect_uri honors explicit env override" do
    with_env("GOOGLE_OAUTH_REDIRECT_URI" => "https://acct.example.com/auth/google_oauth2/callback") do
      assert_equal "https://acct.example.com/auth/google_oauth2/callback", GoogleOauth.redirect_uri
    end
  end

  private

  def with_env(vars)
    previous = vars.keys.index_with { |k| ENV[k] }
    vars.each { |k, v| ENV[k] = v }
    yield
  ensure
    previous.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
  end
end
