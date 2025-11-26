Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"
# Route pour le profil (utiliser la ressource 'resource' car il n'y a qu'un profil par utilisateur connecté)
  resource :profile, only: [:show] do
    # Actions spécifiques non-RESTful
    get :favorites, on: :collection
    get :settings, on: :collection
  end

  resources :chats, only: [:index, :new, :create, :show, :destroy] do
    resources :messages, only: [:index, :create]
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  resources :chats
end
