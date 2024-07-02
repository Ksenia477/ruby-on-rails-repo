Rails.application.routes.draw do
  # root 'home#index'
  root 'landing#index'
  get  '/callback' => 'landing#callback'
  get "up" => "rails/health#show", as: :rails_health_check
end
