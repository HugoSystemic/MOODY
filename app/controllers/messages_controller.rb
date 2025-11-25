class MessagesController < ActionController::Base
before_action :authenticate_user!
before_action :set_chat

  # GET /chats/:chat_id/messages
  def index
    @messages = @chat.messages.order(created_at: :asc)
    @message = Message.new
  end

  # POST /chats/:chat_id/messages
  def create
    @message = Message.new(message_params)
    @message.chat = @chat
    @message.role = 'user' # Le rôle de l'utilisateur est fixé ici

    if @message.save

      messages_for_api = build_messages_for_api

      client = OpenAI::Client.new

      begin
        response = client.chat(
          parameters: {
            model: "gpt-3.5-turbo",
            messages: messages_for_api,
            response_format: { type: "json_object" }
          }
        )

        ai_content_json = response.choices.first.message.content
        response_data = JSON.parse(ai_content_json)

        @chat.messages.create!(
          role: 'assistant',
          content: response_data['ambiance_description']
        )

        response_data['youtube_videos'].each do |video|
          @chat.musics.create!(
            title: video['title'],
            youtube_url: video['url'],
            youtube_video_id: video['video_id'],
          )
        end

        redirect_to chat_path(@chat)

      rescue JSON::ParserError, NoMethodError => e
        flash[:alert] = "Erreur: L'IA a généré une réponse invalide. Veuillez réessayer."
        redirect_to chat_messages_path(@chat)
      rescue => e
        flash[:alert] = "Erreur lors de l'appel à l'API. Veuillez vérifier la configuration: #{e.message}"
        redirect_to chat_messages_path(@chat)
      end

    else
      @messages = @chat.messages.order(created_at: :asc)
      render :index, status: :unprocessable_entity
    end
  end

  private

  def set_chat
    @chat = Chat.find(params[:chat_id])
  end

  def message_params
    params.require(:message).permit(:content)
  end

  def build_messages_for_api
    system_prompt_template = <<~PROMPT
      Tu es un curateur musical expert et un DJ IA, appelé "Moody". Ton rôle est d'interpréter l'état d'esprit et l'activité de l'utilisateur pour lui fournir l'ambiance sonore idéale sur YouTube.

    --- CONTEXTE DE LA SESSION ---
    Les paramètres actuels de la session sont : Activité : #{chat.activity}, Mood : #{chat.mood}, Durée : #{chat.duration_minutes} minutes.

    --- RÈGLES DE FORMAT ---
    Ton output doit toujours suivre deux parties : 1. Ta réponse textuelle. 2. UN BLOC DE CODE JSON STRICT à la fin, sans autre texte après. Le JSON DOIT contenir : {"title": "Titre court de l'ambiance", "videos": [ {"video_url": "URL_YOUTUBE_1"}, ... 5 au total ]}.
  PROMPT


    messages = @chat.messages.order(created_at: :asc).map do |message|
      {
        role: message.role,
        content: message.content
      }
    end

    messages.prepend({ role: 'system', content: system_prompt_template })
    return messages
  end
end
