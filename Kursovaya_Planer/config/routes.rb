Rails.application.routes.draw do
  root 'home#index'
  # post '/task', to: 'task#create'
  # patch '/task/:id', to:'task#update'
  # delete '/task/:id', to: 'task#destroy'
  resources :task
  get 'home/show_schedule/:day', to: 'home#show_schedule', as: 'show_schedule'
end
