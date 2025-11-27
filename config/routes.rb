Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"

  resource :profile, only: [:show] do
    get :favorites, on: :collection
    get :settings, on: :collection
  end

  resources :chats, only: [:index, :new, :create, :show, :destroy] do
    resources :messages, only: [:index, :create]
    member do
      # Ajout de la route pour basculer l'état "liked"
      patch :toggle_favorite
    end
  end

  resources :musics, only: [:index]

  resources :favorites, only: [:index], controller: 'favorites'
end
