Rails.application.routes.draw do
#GetBack::Engine.routes.draw do
  resources :db_backups do
    post :restore
  end

  resources :file_backups do
    post :restore
  end

  post :confirm, :to => 'aws_sns_subscriptions#create'
end
