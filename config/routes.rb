Rails.application.routes.draw do

  get 'matchmaking/welcome'

  get 'matchmaking/lobby_list', as: 'lobby_list'

  post 'matchmaking/ranked_match', as: 'start_ranked'

  post 'matchmaking/friendly_match', as: 'start_friendly'

  post 'matchmaking/open_match', as: 'start_open'

  post 'matchmaking/spectate', as: 'start_spectate'

  post 'matchmaking/join', as: 'join_match'

  get 'matches/:id' => 'matchmaking#match', as: 'match'

  root to: 'matchmaking#welcome'
  mount ActionCable.server => '/cable'

  get 'administration' => 'welcome#administration'

  resources :users
  resources :shapes
  resources :players

  controller :sessions do
    get 'login' => :new
    post 'login' => :create
    get 'logout' => :destroy
  end
  get 'register' => 'users#new', as: 'register'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
