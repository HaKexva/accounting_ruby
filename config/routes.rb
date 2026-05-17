Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  get "login", to: "sessions#new", as: :login
  post "login/trial", to: "sessions#trial", as: :trial_login
  delete "logout", to: "sessions#destroy", as: :logout
  get "/auth/:provider/callback", to: "oauth_callbacks#create", as: :oauth_callback
  get "/auth/failure", to: "oauth_callbacks#failure", as: :oauth_failure

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "dashboard#index"
  get "expenses/history", to: "dashboard#history", as: :expense_history
  post   "actual_expenditures", to: "actual_expenditures#create", as: :actual_expenditures
  patch  "actual_expenditures/:id", to: "actual_expenditures#update", as: :actual_expenditure
  delete "actual_expenditures/:id", to: "actual_expenditures#destroy"

  get "budgets", to: "budgets#index", as: :budgets
  post   "budgets/revenue_budgets", to: "budgets#create_revenue_budget", as: :budget_revenue_budgets
  patch  "budgets/revenue_budgets/:id", to: "budgets#update_revenue_budget", as: :budget_revenue_budget
  delete "budgets/revenue_budgets/:id", to: "budgets#destroy_revenue_budget", as: :delete_budget_revenue_budget
  post   "budgets/expenditure_budgets", to: "budgets#create_expenditure_budget", as: :budget_expenditure_budgets
  patch  "budgets/expenditure_budgets/:id", to: "budgets#update_expenditure_budget", as: :budget_expenditure_budget
  delete "budgets/expenditure_budgets/:id", to: "budgets#destroy_expenditure_budget", as: :delete_budget_expenditure_budget
  get "revenue_budgets", to: redirect("/budgets")
  get "expenditure_budgets", to: redirect("/budgets")
  get "settings", to: "settings#index", as: :settings
  post   "settings/taxonomy_items", to: "settings#create_taxonomy_item", as: :settings_taxonomy_items
  patch  "settings/taxonomy_items/:id", to: "settings#update_taxonomy_item", as: :settings_taxonomy_item
  delete "settings/taxonomy_items/:id", to: "settings#destroy_taxonomy_item", as: :delete_settings_taxonomy_item
end
