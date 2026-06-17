# frozen_string_literal: true

module Authentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_user, :signed_in?
    before_action :authenticate_user!
  end

  private

  def current_user
    session_user_id = session[:user_id].presence&.to_i
    if session_user_id.blank?
      @current_user = nil
      return nil
    end

    if defined?(@current_user) && @current_user&.id == session_user_id
      return @current_user
    end

    @current_user = User.find_by(id: session_user_id)
  end

  def signed_in?
    current_user.present?
  end

  def authenticate_user!
    return if signed_in?
    return if allow_anonymous_trial?

    store_return_location
    redirect_to login_path, alert: "請先登入。"
  end

  def store_return_location
    return unless request.get? && !request.xhr?

    session[:return_to_after_login] = request.fullpath
  end

  def after_login_path
    session.delete(:return_to_after_login).presence || root_path
  end

  def localhost_request?
    request.present? && LocalHostAccess.localhost_host?(request.host)
  end

  # No Google credentials yet (e.g. Railway before env vars are set).
  def oauth_login_required?
    GoogleOauth.configured?
  end

  # Development, localhost, or deploy without OAuth: automatic trial user.
  def skip_login_page?
    return false if Rails.env.test?

    !oauth_login_required? || Rails.env.local? || localhost_request?
  end

  def allow_anonymous_trial?
    Rails.env.test? || skip_login_page?
  end
end
