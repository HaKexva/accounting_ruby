# frozen_string_literal: true

module Authentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_user, :signed_in?
    before_action :authenticate_user!
  end

  private

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = User.find_by(id: session[:user_id]) if session[:user_id].present?
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

  def allow_anonymous_trial?
    Rails.env.test? || (Rails.env.local? && !GoogleOauth.configured?)
  end
end
