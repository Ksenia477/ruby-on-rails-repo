Rails.application.routes.draw do
  devise_for :users
  root to: 'home#index'
  get 'home/show_schedule/:day', to: 'home#show_schedule', as: 'show_schedule'
  post 'home/save_schedule/:day', to: 'home#save_schedule', as: 'save_schedule'
  resources :tasks, only: [:create, :edit, :update, :destroy]
  post 'home/optimize_schedule', to: 'home#optimize_schedule'
  post 'home/shift_schedule', to: 'home#shift_schedule'
  post 'home/apply_optimization', to: 'home#apply_optimization'
  post 'home/merge_tasks', to: 'home#merge_tasks'
  post 'home/transfer_task', to: 'home#transfer_task'
end
