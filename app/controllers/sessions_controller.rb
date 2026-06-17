# frozen_string_literal: true

class SessionsController < ApplicationController
  skip_before_action :authenticate_user!
  layout "sessions"

  def new
    redirect_to after_login_path if signed_in? || skip_login_page?

    @google_oauth_enabled = GoogleOauth.configured?
    @trial_login_enabled = allow_anonymous_trial?
  end

  def trial
    unless allow_anonymous_trial?
      redirect_to login_path, alert: "目前需使用 Google 登入。"
      return
    end

    user = ensure_trial_user_record
    ExpenditureTaxonomy.ensure_seeded!(user)
    session[:user_id] = user.id
    redirect_to after_login_path, notice: "已以試用帳號登入。"
  end

  def destroy
    reset_session
    destination = skip_login_page? ? root_path : login_path
    redirect_to destination, notice: "已登出。"
  end
end
