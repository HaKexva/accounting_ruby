# frozen_string_literal: true

# Until auth is wired, resolve the acting user from `current_user` or the first
# persisted user, else a dedicated local trial row (same as budgets).
module TrialAccount
  extend ActiveSupport::Concern

  TRIAL_USER_EMAIL = "trial@local.app"
  TRIAL_USER_GOOGLE_UID = "local-trial-user"

  private

  def trial_account_owner
    user = current_user if respond_to?(:current_user, true)
    return user if user.present?

    User.order(:id).first || ensure_trial_user_record
  end

  def ensure_trial_user_record
    User.find_or_create_by!(email: TRIAL_USER_EMAIL) do |u|
      u.google_uid = TRIAL_USER_GOOGLE_UID
    end
  end
end
