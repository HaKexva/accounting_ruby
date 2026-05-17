# frozen_string_literal: true

# Resolves the acting user: signed-in account, or local trial row when OAuth is not configured.
module TrialAccount
  extend ActiveSupport::Concern

  TRIAL_USER_EMAIL = "trial@local.app"
  TRIAL_USER_GOOGLE_UID = "local-trial-user"

  private

  def trial_account_owner
    return current_user if signed_in?

    if Rails.env.test?
      return User.find_by(id: session[:user_id]) if session[:user_id].present?

      return User.order(:id).first
    end

    ensure_trial_user_record if allow_anonymous_trial?
  end

  def ensure_trial_user_record
    User.find_or_create_by!(google_uid: TRIAL_USER_GOOGLE_UID) do |u|
      u.email = TRIAL_USER_EMAIL
    end
  end
end
