# frozen_string_literal: true

# Google OAuth2 credentials and redirect URI (GOOGLE_CLIENT_ID / GOOGLE_CLIENT_SECRET). Zeitwerk: GoogleOauth.
module GoogleOauth
  CALLBACK_PATH = "/auth/google_oauth2/callback"

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

  # Hostname only — no scheme, path, or port (unless non-default).
  def app_host
    normalize_host(ENV["APP_HOST"].presence || ENV["RAILWAY_PUBLIC_DOMAIN"].presence)
  end

  def normalize_host(raw)
    return nil if raw.blank?

    host = raw.to_s.strip
    host = host.sub(%r{\Ahttps?://}i, "")
    host = host.delete_prefix("//")
    host = host.delete_suffix("/")
    host.split("/").first.presence
  end

  # Must match Google Cloud Console "Authorized redirect URIs" exactly.
  def redirect_uri
    explicit = ENV["GOOGLE_OAUTH_REDIRECT_URI"].to_s.strip
    return explicit if explicit.present?

    if Rails.env.production?
      host = app_host
      return "https://#{host}#{CALLBACK_PATH}" if host.present?
    end

    port = ENV.fetch("PORT", 3000)
    "http://localhost:#{port}#{CALLBACK_PATH}"
  end
end
