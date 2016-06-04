Rails.application.routes.draw do

  root to: 'welcome#welcome'

  get 'matchmaking' => 'welcome#matchmaking'

  get 'spectating' => 'welcome#spectating'

  get 'administration' => 'welcome#administration'

  resources :users
  resources :shapes
  resources :players
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
