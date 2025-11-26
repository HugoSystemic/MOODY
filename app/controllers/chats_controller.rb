class ChatsController < ApplicationController
  before_action :set_chat, only: [:show, :edit, :update, :destroy]
  SYSTEM_PROMPT_FOR_MOOD = "Please return a json format with this keys : { 'message'=> String, 'mood'=> the mood, 'found'=> true/false if you managed to find a mood }\n\n the key 'message' should return a short text to resume the mood of the user from the message and ask him what activity he will do and for how long \n\n "

  def index
    @chats = Chat.all.order(created_at: :desc)
  end

  def show
    @messages = @chat.messages.order(created_at: :asc)
    @message = Message.new()
  end

  def create
    @chat = current_user.chats.new(chat_params)

    if @chat.save
      if params[:message].present? && params[:message][:content].present?
        @message = @chat.messages.new(
          content: params[:message][:content],
          role: 'user'
        )

        if @message.save
          @ruby_llm_chat = RubyLLM.chat
          build_conversation_history()

          response = @ruby_llm_chat.with_instructions(SYSTEM_PROMPT_FOR_MOOD).ask(@message.content)
          parsed_response = JSON.parse(response.content)
          if parsed_response["found"] == true
            @chat.update(mood: parsed_response["mood"])
            @chat.messages.create(role: "assistant", content: parsed_response["message"])
          end
        else
          #
        end
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

  def build_conversation_history
    @chat.messages.each do |message|
      @ruby_llm_chat.add_message(message)
    end
  end
end
