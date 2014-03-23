BtiScraper::Application.routes.draw do
  devise_for :users
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  namespace :api, defaults: {format: 'json'} do
    namespace :v1 do 
      resources :products
    end
  end

  resources :users
  get '/documentation', to: 'public#documentation'
  get '/account', to: 'user#show'
  get '/user/regen_key', to: 'user#regen_key'

  root 'public#index'

end
