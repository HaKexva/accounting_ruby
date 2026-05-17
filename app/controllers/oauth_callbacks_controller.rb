# frozen_string_literal: true

class OauthCallbacksController < ApplicationController
  skip_before_action :authenticate_user!

  def create
    auth = request.env["omniauth.auth"]
    unless auth
      redirect_to login_path, alert: "登入失敗，請再試一次。"
      return
    end

    user = User.from_omniauth(auth)
    ExpenditureTaxonomy.ensure_seeded!(user)
    session[:user_id] = user.id
    redirect_to after_login_path, notice: "登入成功。"
  rescue ActiveRecord::RecordInvalid
    redirect_to login_path, alert: "無法建立帳號，請確認 Google 帳號有提供電子郵件。"
  end

  def failure
    redirect_to login_path, alert: "登入失敗：#{failure_message}"
  end

  private

  def failure_message
    params[:message].presence || "未知錯誤"
  end
end
