Rails.application.routes.draw do
  devise_for :users
  root to: 'home#index'
  get 'home/show_schedule/:day', to: 'home#show_schedule', as: 'show_schedule'
  post 'home/save_schedule/:day', to: 'home#save_schedule', as: 'save_schedule'
end
