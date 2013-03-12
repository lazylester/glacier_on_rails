GetBack::Engine.routes.draw do
  resources :backups do
    post :restore
  end
end
