Rails.application.routes.draw do
#GetBack::Engine.routes.draw do
  resources :db_backups do
    post :restore
  end

  resources :file_backups do
    post :restore
  end

  namespace :aws do
    get :confirm
  end
end
