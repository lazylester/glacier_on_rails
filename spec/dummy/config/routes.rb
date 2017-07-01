Rails.application.routes.draw do

  mount GlacierOnRails::Engine => "/"
  get 'admin', :to => 'admin#index'
end
