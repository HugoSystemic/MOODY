Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"

  resource :profile, only: [:show] do
    get :favorites, on: :collection
    get :settings, on: :collection
  end

  resources :chats, only: [:index, :new, :create, :show, :destroy] do
    resources :messages, only: [:index, :create]
  end
  
  resources :musics, only: [:index]

  resources :chats
end
