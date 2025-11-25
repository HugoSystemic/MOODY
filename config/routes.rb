Rails.application.routes.draw do
  root "pages#home"

  devise_for :users

  resources :chats
end
