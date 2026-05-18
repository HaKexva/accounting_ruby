# frozen_string_literal: true

require "omniauth/rails_csrf_protection"
require Rails.root.join("app/models/google_oauth")

client_id = ENV["GOOGLE_CLIENT_ID"].to_s.strip
client_secret = ENV["GOOGLE_CLIENT_SECRET"].to_s.strip

if client_id.present? && client_secret.present?
  redirect_uri = GoogleOauth.redirect_uri

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
