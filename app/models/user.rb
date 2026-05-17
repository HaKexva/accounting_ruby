class User < ApplicationRecord
  has_many :revenue_budgets, class_name: "RevenueBudget", inverse_of: :user, dependent: :destroy
  has_many :expenditure_budgets, class_name: "ExpenditureBudget", inverse_of: :user, dependent: :destroy
  has_many :actual_expenditures, class_name: "ActualExpenditure", inverse_of: :user, dependent: :destroy
  has_many :expenditure_taxonomy_items, dependent: :destroy

  validates :google_uid, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true

  def self.from_omniauth(auth)
    uid = auth.uid.to_s
    email = auth.info.email.to_s.strip.downcase
    if uid.blank? || email.blank?
      user = new
      user.errors.add(:base, "missing Google uid or email")
      raise ActiveRecord::RecordInvalid, user
    end

    record = find_or_initialize_by(google_uid: uid)
    record.email = email
    record.save!
    record
  end
end
