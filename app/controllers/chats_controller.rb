class ChatsController < ApplicationController
  before_action :set_chat, only: [:show, :edit, :update, :destroy]

  def index
    @chats = Chat.all.order(created_at: :desc)
  end

  def show
    @messages = @chat.messages.order(created_at: :asc)
    @musics   = @chat.musics
  end

  def create
    @chat = current_user.chats.new(chat_params)

    if @chat.save
     if params[:message].present? && params[:message][:content].present?
        @chat.messages.create(
          content: params[:message][:content],
          role: 'user'
        )
      end

      redirect_to @chat, notice: "Chat créé avec succès !"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @chat.update(chat_params)
      redirect_to @chat, notice: "Chat mis à jour !"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @chat.destroy
      flash[:alert] = "Chat supprimé."
      redirect_to chats_path
  end

  private

  def set_chat
    @chat = Chat.find(params[:id])
  end

  def chat_params
    params.require(:chat).permit(:title, :mood, :activity, :duration)
  end
end
