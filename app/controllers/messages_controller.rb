class MessagesController < ApplicationController
  before_action :authenticate_user!

  SYSTEM_PROMPT_FOR_ACTIVITIES = "Can you find an activity and a duration depending on that message \n\n Please return a json format with this keys : { 'message'=> une réponse récapitulant les infos du message du user, 'activity'=> an activity, 'duration'=> a duration in seconds, 'found'=> true/false if you managed to find an activity and a duration }\n\n the key 'message' should return a message with a link to a youtube video that match my mood, activity and duration"
  SYSTEM_PROMPT_MUSIC_URLS = "Return a message with a link to a youtube video that match my mood, activity and duration"

  # GET /chats/:chat_id/messages
  def index
    @chat = Chat.find(params[:chat_id])
    @messages = @chat.messages.order(created_at: :asc)
    @message = Message.new
  end

  # POST /chats/:chat_id/messages
  def create
    @chat = Chat.find(params[:chat_id])
    @message = Message.new(message_params)
    @message.chat = @chat
    @message.role = 'user' # Le rôle de l'utilisateur est fixé ici

    if @message.save
      @ruby_llm_chat = RubyLLM.chat
      build_conversation_history()

      if @chat.messages.where(role: 'assistant').size == 1 || @chat.messages.where(role: 'assistant').size.zero?
        response = @ruby_llm_chat.with_instructions(SYSTEM_PROMPT_FOR_ACTIVITIES).ask(@message.content)
        parsed_response = JSON.parse(response.content)
        if parsed_response["found"] == true
          @chat.update(activity: parsed_response["activity"], duration: parsed_response["duration"])
          @chat.messages.create(role: "assistant", content: parsed_response["message"])
        end
      else
        response = @ruby_llm_chat.with_instructions(SYSTEM_PROMPT_MUSIC_URLS).ask(@message.content)
        @chat.messages.create(role: "assistant", content: response.content)
      end

      @chat.generate_title_from_first_message()
      redirect_to @chat
    else
      render "chats/show", status: :unprocessable_entity
    end


    # if @chat.messages.where(role: 'assistant').size == 1
    #   # mettre à jour le mood du chat
    # elsif @chat.messages.where(role: 'assistant').size == 2
    #   # mettre à jour activity et duration
    # end

    # if @message.save
    #     unless @chat.parameters_complete?
    #       extract_session_parameters
    #     end
    #     if @chat.parameters_complete?
    #       process_music_generation
    #       redirect_to chat_path(@chat)
    #     else
    #       ask_for_missing_parameters
    #       redirect_to chat_messages_path(@chat)
    #     end
    #   else
    #     @messages = @chat.messages.order(created_at: :asc)
    #     render :index, status: :unprocessable_entity
    #   end
    # end
  end

  private

  def message_params
    params.require(:message).permit(:content)
  end

  def build_conversation_history
    @chat.messages.each do |message|
      @ruby_llm_chat.add_message(message)
    end
  end

  def instructions
    [SYSTEM_PROMPT, challenge_context, @challenge.system_prompt]
    .compact.join("\n\n")
end
end
