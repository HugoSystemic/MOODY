# app/controllers/profiles_controller.rb
class ProfilesController < ApplicationController
  # ⚠️ Sécurité : Devise s'assure que l'utilisateur est connecté pour toutes les actions
  before_action :authenticate_user!

  # 1. Action : Afficher les détails du profil
  # Correspond à la route GET /profile
  def show
    # Dans une application Devise, 'current_user' est l'utilisateur connecté
    @user = current_user
    # Le fichier de vue est app/views/profiles/show.html.erb
  end

  # 2. Action : Afficher les musiques favorites
  # Correspond à la route GET /profile/favorites
  def favorites
    @user = current_user

    # 🔎 Logique des favoris (basée sur votre schéma de BDD)
    # Récupère toutes les entrées dans la table 'musics' qui sont liées à l'utilisateur ET où 'liked' est à true
    @favorite_musics = Music.where(user: @user, liked: true).order(created_at: :desc)

    # Le fichier de vue est app/views/profiles/favorites.html.erb
  end

  # 3. Action : Afficher les paramètres du compte
  # Correspond à la route GET /profile/settings
  def settings
    @user = current_user
    # Cette vue affichera les liens vers les actions Devise (déconnexion, suppression, etc.)

    # Le fichier de vue est app/views/profiles/settings.html.erb
  end

  # Note : La modification de l'email/mot de passe/suppression du compte est gérée par Devise
  # via le RegistrationsController (edit_user_registration_path), non nécessaire ici.
end
