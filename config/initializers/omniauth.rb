# frozen_string_literal: true

require "omniauth/rails_csrf_protection"

client_id = ENV["GOOGLE_CLIENT_ID"].to_s.strip
client_secret = ENV["GOOGLE_CLIENT_SECRET"].to_s.strip

def google_oauth_redirect_uri
  explicit = ENV["GOOGLE_OAUTH_REDIRECT_URI"].to_s.strip
  return explicit if explicit.present?

  if Rails.env.production?
    host = ENV["APP_HOST"].presence || ENV["RAILWAY_PUBLIC_DOMAIN"].presence
    return "https://#{host}/auth/google_oauth2/callback" if host.present?
  end

  port = ENV.fetch("PORT", 3000)
  "http://localhost:#{port}/auth/google_oauth2/callback"
end

if client_id.present? && client_secret.present?
  redirect_uri = google_oauth_redirect_uri

  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :google_oauth2,
             client_id,
             client_secret,
             {
               scope: "email,profile",
               prompt: "select_account",
               image_aspect_ratio: "square",
               image_size: 50,
               redirect_uri: redirect_uri
             }
  end

  Rails.application.config.after_initialize do
    Rails.logger.info("[OmniAuth] Google redirect_uri=#{redirect_uri}")
  end
end

OmniAuth.config.allowed_request_methods = %i[post get]
OmniAuth.config.silence_get_warning = true
