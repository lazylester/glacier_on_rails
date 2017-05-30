Rails.application.routes.draw do

  mount GetBack::Engine => "/"
  get 'admin', :to => 'admin#index'
end
