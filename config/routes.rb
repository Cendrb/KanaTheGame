Rails.application.routes.draw do

  root to: 'welcome#welcome'
  mount ActionCable.server => '/cable'

  get 'matchmaking' => 'welcome#matchmaking'

  get 'spectating' => 'welcome#spectating'

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
