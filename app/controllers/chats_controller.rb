class ChatsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_chat, only: [:show, :edit, :update, :destroy]

  def index
    @chats = Chat.all.order(created_at: :desc)
  end

  def show
    @messages = @chat.messages.order(created_at: :asc)
    @message = Message.new()
    # @musics   = @chat.musics
  end

  def new
    @chat = Chat.new
  end

  def create
    @chat = current_user.chats.new(chat_params)

    if @chat.save
      # créer le message et je met à jour le mood de @chat

      redirect_to @chat
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @chat.update(chat_params)
      redirect_to @chat, notice: "Session mise à jour !"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @chat = Chat.find(params[:id])
    @chat.destroy
    redirect_to chats_path, notice: "Session supprimée."
  end

  private

  def set_chat
    @chat = Chat.find(params[:id])
  end

  def chat_params
    params.require(:chat).permit(:title)
  end
end
