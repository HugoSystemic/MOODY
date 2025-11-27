class FavoritesController < ApplicationController
  before_action :authenticate_user!

  def index
    @favorite_chats = current_user.chats.where(favorited: true).order(created_at: :desc)
  end
end
