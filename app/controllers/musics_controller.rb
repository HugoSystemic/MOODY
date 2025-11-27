class MusicsController < ApplicationController
  before_action :authenticate_user!

  def index
    @musics = Music.joins(:chat)
                   .where(chats: { user_id: current_user.id })
                   .order(created_at: :desc)
  end
end
