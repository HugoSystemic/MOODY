# app/controllers/chats_controller.rb

class ChatsController < ApplicationController
  before_action :set_chat, only: %i[show edit update destroy toggle_favorite]
  before_action :authenticate_user!

  SYSTEM_PROMPT_FOR_MOOD = "Please return a json format with this keys : { 'message'=> String, 'mood'=> the mood, 'found'=> true/false if you managed to find a mood }\n\n the key 'message' should return a short text to resume the mood of the user from the message and ask him what activity he will do and for how long \n\n "

  # GET /chats
  def index
    # 1. Scope initial : uniquement les chats de l'utilisateur courant, triés
    chats_scope = current_user.chats.order(created_at: :desc)

    # 2. Application du filtre "Favoris" (basé sur params[:liked])
    if params[:liked].present? && params[:liked] == 'true'
      @chats = chats_scope.where(liked: true)
      @filter_title = "Favoris"
    else
      @chats = chats_scope
      @filter_title = "Toutes les sessions"
    end
  end

  # GET /chats/:id
  def show
    @messages = @chat.messages.order(created_at: :asc)
    @message = Message.new
  end

  def create
    @chat = current_user.chats.new(chat_params)

    @chat.title = Chat::DEFAULT_TITLE

    if @chat.save
      if params[:message].present? && params[:message][:content].present?
        @message = @chat.messages.new(
          content: params[:message][:content],
          role: 'user'
        )
        if @message.save
          @chat.generate_title_from_first_message

          @ruby_llm_chat = RubyLLM.chat
          build_conversation_history

          response = @ruby_llm_chat.with_instructions(SYSTEM_PROMPT_FOR_MOOD).ask(@message.content)
          parsed_response = begin
            JSON.parse(response.content)
          rescue StandardError
            {}
          end

          if parsed_response["found"] == true
            @chat.update(mood: parsed_response["mood"])
            @chat.messages.create(role: "assistant", content: parsed_response["message"])
          end
        end
      end

      redirect_to @chat, notice: "Chat créé avec succès !"

    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /chats/:id/edit
  def edit
  end

  # PATCH/PUT /chats/:id
  def update
    if @chat.update(chat_params)
      redirect_to @chat, notice: "Chat mis à jour !"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /chats/:id
  def destroy
    @chat.destroy
    flash[:alert] = "Chat supprimé."
    redirect_to chats_path
  end

  # PATCH /chats/:id/toggle_favorite
  def toggle_favorite
    # Bascule la valeur de la colonne 'liked' et la sauvegarde
    @chat.toggle!(:liked)

    respond_to do |format|
      # Redirection HTML classique
      format.html do
        flash[:notice] = @chat.liked ? "Ajouté aux favoris." : "Retiré des favoris."
        redirect_back(fallback_location: @chat)
      end
      # Réponse Turbo Stream
      format.turbo_stream
    end
  end

  private

  def set_chat
    @chat = current_user.chats.find(params[:id])
  end

  def chat_params
    params.require(:chat).permit(:title, :mood, :activity, :duration)
  end

  def build_conversation_history
    @chat.messages.each do |message|
      @ruby_llm_chat.add_message(message)
    end
  end
end
