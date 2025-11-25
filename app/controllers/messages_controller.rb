class MessagesController < ActionController::Base
before_action :authenticate_user!
before_action :set_chat

  # GET /chats/:chat_id/messages
  def index
  # Récupérer tous les messages du chat, ordonnés chronologiquement
    @messages = @chat.messages.order(created_at: :asc)
  # Préparer un nouvel objet Message pour le formulaire d'envoi
    @message = Message.new
  end

  # POST /chats/:chat_id/messages
  def create
    @message = Message.new(message_params)
    @message.chat = @chat
    @message.role = 'user' # Le rôle de l'utilisateur est fixé ici

    if @message.save
      # --- LOGIQUE D'INTÉGRATION DE L'IA ---

      # 1. Préparer les messages (historique + prompt système) pour l'API OpenAI
      messages_for_api = build_messages_for_api

      # 2. Configurer le client OpenAI
      # NOTE: Assurez-vous que l'environnement Rails a accès à la clé API (ENV['OPENAI_ACCESS_TOKEN']).
      client = OpenAI::Client.new

      # 3. Appel à l'API (avec gestion des erreurs)
      begin
        response = client.chat(
          parameters: {
            model: "gpt-3.5-turbo",
            messages: messages_for_api,
            # Demande un format JSON structuré, crucial pour le parsing
            response_format: { type: "json_object" }
          }
        )

        # Récupérer et parser le contenu JSON généré par l'IA
        ai_content_json = response.choices.first.message.content
        response_data = JSON.parse(ai_content_json) # Convertir la chaîne JSON en Hash Ruby

        # 4. Sauvegarder la réponse textuelle de l'IA (message de l'assistant)
        @chat.messages.create!(
          role: 'assistant',
          content: response_data['ambiance_description']
        )

        # 5. Sauvegarder la playlist générée (musics)
        response_data['youtube_videos'].each do |video|
          @chat.musics.create!(
            title: video['title'],
            youtube_url: video['url'],
            youtube_video_id: video['video_id'],
            # Les FK chat_id et user_id (via association) sont gérées automatiquement
          )
        end

        # Rediriger l'utilisateur vers la page finale (show du chat)
        redirect_to chat_path(@chat)

      rescue JSON::ParserError, NoMethodError => e
        flash[:alert] = "Erreur: L'IA a généré une réponse invalide. Veuillez réessayer."
        redirect_to chat_messages_path(@chat)
      rescue => e
        flash[:alert] = "Erreur lors de l'appel à l'API. Veuillez vérifier la configuration: #{e.message}"
        redirect_to chat_messages_path(@chat)
      end

    else
      # En cas d'échec de la validation du message utilisateur
      @messages = @chat.messages.order(created_at: :asc)
      render :index, status: :unprocessable_entity
    end
  end

  private

  # Définition du Chat parent à partir de l'URL (params[:chat_id])
  def set_chat
    @chat = Chat.find(params[:chat_id])
  end

  # Strong Params : Sécurité pour n'autoriser que le champ 'content'
  def message_params
    params.require(:message).permit(:content)
  end

  # Prépare le prompt système et l'historique de la conversation pour l'API.
  def build_messages_for_api
    # 1. Définition du prompt système avec l'interpolation des variables du chat
    system_prompt_template = <<~PROMPT
      Tu es un curateur musical expert et un DJ IA, appelé "Moody". Ton rôle est d'interpréter l'état d'esprit et l'activité de l'utilisateur pour lui fournir l'ambiance sonore idéale sur YouTube.

    --- CONTEXTE DE LA SESSION ---
    Les paramètres actuels de la session sont : Activité : #{chat.activity}, Mood : #{chat.mood}, Durée : #{chat.duration_minutes} minutes.

    --- RÈGLES DE FORMAT ---
    Ton output doit toujours suivre deux parties : 1. Ta réponse textuelle. 2. UN BLOC DE CODE JSON STRICT à la fin, sans autre texte après. Le JSON DOIT contenir : {"title": "Titre court de l'ambiance", "videos": [ {"video_url": "URL_YOUTUBE_1"}, ... 5 au total ]}.
  PROMPT


    # 2. Récupérer l'historique des messages pour donner du contexte à l'IA
    messages = @chat.messages.order(created_at: :asc).map do |message|
      {
        role: message.role,
        content: message.content
      }
    end

    # 3. Ajouter le prompt système personnalisé en tête de la conversation
    messages.prepend({ role: 'system', content: system_prompt_template })
    return messages
  end
end
