class MusicsController < ApplicationController
  before_action :authenticate_user!

  # GET /musics
  def index
    # Récupère toutes les musiques en faisant une jointure (JOIN) avec la table 'chats'
    # et filtre uniquement celles où le user_id du chat correspond à l'utilisateur courant.
    @musics = Music.joins(:chat)
                   .where(chats: { user_id: current_user.id })
                   .order(created_at: :desc)
  end
end
