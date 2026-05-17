# frozen_string_literal: true

# Google OAuth2 credentials (GOOGLE_CLIENT_ID / GOOGLE_CLIENT_SECRET). Zeitwerk: GoogleOauth.
module GoogleOauth
  module_function

  def configured?
    client_id.present? && client_secret.present?
  end

  def client_id
    ENV["GOOGLE_CLIENT_ID"].to_s.strip
  end

  def client_secret
    ENV["GOOGLE_CLIENT_SECRET"].to_s.strip
  end
end
