BtiScraper::Application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  namespace :api, defaults: {format: 'json'} do
    namespace :v1 do 
      resources :products
    end
  end

  root 'welcome#index'

end
