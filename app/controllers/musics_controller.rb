# app/controllers/musics_controller.rb

class MusicsController < ApplicationController
  before_action :authenticate_user!

  # GET /musics
  def index
    # Changement crucial : Ajouter '::' devant Music pour indiquer la racine de la classe
    @musics = ::Music.joins(:chat)
                   .where(chats: { user_id: current_user.id })
                   .order(created_at: :desc)
  end
end
