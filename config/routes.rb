require 'sidekiq/web'


BtiScraper::Application.routes.draw do
  devise_for :users
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".
  mount Sidekiq::Web => '/sidekiq'

  namespace :api, defaults: {format: 'json'} do
    namespace :v1 do 
      resources :categories
      resources :products
      resources :product_groups
    end
  end

  resources :users
  get '/documentation', to: 'public#documentation'
  get '/contact', to: 'public#contact'
  get '/account', to: 'user#show'
  get '/user/regen_key', to: 'user#regen_key'

  root 'public#index'

end
