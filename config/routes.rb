Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"

  resource :profile, only: [:show, :update] do
    get :settings
    get :favorites
  end

  resources :chats, only: [:index, :new, :create, :show, :destroy] do
    resources :messages, only: [:index, :create]
  end

  resources :musics, only: [:index]

  resources :chats
end
