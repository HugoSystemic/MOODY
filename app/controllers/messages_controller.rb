class MessagesController < ApplicationController
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

    if @chat.messages.where(role: 'assistant').size == 1
      # mettre à jour le mood du chat
    elsif @chat.messages.where(role: 'assistant').size == 2
      # mettre à jour activity et duration
    end

    if @message.save
        unless @chat.parameters_complete?
          extract_session_parameters
        end
        if @chat.parameters_complete?
          process_music_generation
          redirect_to chat_path(@chat)
        else
          ask_for_missing_parameters
          redirect_to chat_messages_path(@chat)
        end
      else
        @messages = @chat.messages.order(created_at: :asc)
        render :index, status: :unprocessable_entity
      end
    end
  end

  private

# 1. Extraction des paramètres pour mettre à jour le Chat
def extract_session_parameters
    extraction_prompt = <<~PROMPT
    Tu es un assistant d'extraction de données. Analyse le dernier message de l'utilisateur.
    Extrais les trois informations suivantes : 'activity', 'mood', et 'duration_minutes' (en nombre entier).
    Si une information est absente ou peu claire, utilise la valeur "unknown" pour ce champ.

    Ton unique réponse doit être un objet JSON STRICT.

    --- FORMAT JSON SOUHAITÉ ---
    { "activity": "...", "mood": "...", "duration_minutes": [nombre entier ou "unknown"] }

    --- MESSAGE UTILISATEUR À ANALYSER ---
    #{@message.content}
  PROMPT

  client = OpenAI::Client.new
  response = client.chat(
    parameters: {
      model: "gpt-3.5-turbo", # Optimisé pour la rapidité d'extraction
      messages: [ { role: "user", content: extraction_prompt } ],
      response_format: { type: "json_object" }
    }
  )

  # Récupération et parsing
  ai_response_json = response.choices.first.message.content
  data = JSON.parse(ai_response_json)

  # Mise à jour du Chat (uniquement si ce n'est pas "unknown")
  @chat.update(
    activity: data['activity'] unless data['activity'] == 'unknown',
    mood: data['mood'] unless data['mood'] == 'unknown',
    duration_minutes: data['duration_minutes'] unless data['duration_minutes'] == 'unknown'
  )
  rescue JSON::ParserError, NoMethodError => e
  Rails.logger.error "Erreur d'extraction IA: #{e.message}"
end

# 2. Répondre pour demander les informations manquantes
def ask_for_missing_parameters
  missing_info = []
  missing_info << 'activité' unless @chat.activity.present?
  missing_info << 'mood' unless @chat.mood.present?
  missing_info << 'durée' unless @chat.duration_minutes.present?

  assistant_response = if missing_info.size == 1
                         "Désolé, il me manque votre #{missing_info.first}. Pouvez-vous être plus précis ?"
                       else
                         "Désolé, il me manque plusieurs informations pour commencer : #{missing_info.to_sentence}. Pouvez-vous me les donner ?"
                       end

  @chat.messages.create!(role: 'assistant', content: assistant_response)
end

# 3. Génération de musique (reprend la logique de votre code initial)
def process_music_generation
  # Utilisation de l'historique du chat pour le contexte (comme vu dans le cours)
  messages_for_api = build_messages_for_api
  client = OpenAI::Client.new

  response = client.chat(
    parameters: {
      model: "gpt-4-turbo-preview",
      messages: messages_for_api,
      response_format: { type: "json_object" }
    }
  )

  # Parsing et création des messages/musiques (reprendre votre code initial)
  ai_content_json = response.choices.first.message.content
  response_data = JSON.parse(ai_content_json)

  # Création du message de l'IA (Ambiance Description)
  @chat.messages.create!(
    role: 'assistant',
    content: response_data['ambiance_description']
  )

  # Création des objets Music
  response_data['youtube_videos'].each do |video|
    @chat.musics.create!(
      title: video['title'],
      youtube_url: video['url'],
      youtube_video_id: video['video_id'],
      # ✅ Pensez à ajouter ici 'category' et 'duration_minutes' si vous les avez dans le modèle Music
    )
  end

  rescue JSON::ParserError, NoMethodError => e
  flash[:alert] = "Erreur de l'IA (JSON/Parse). Veuillez affiner votre demande."
  @chat.messages.create!(role: 'assistant', content: "Désolé, j'ai eu un problème de format. Pouvez-vous reformuler votre dernière demande?")
end

# 4. Construction de l'historique (méthode existante dans votre code)
def build_messages_for_api
  # Le System Prompt doit inclure le CONTEXTE actuel de la session (@chat.activity, etc.)
  system_prompt_template = <<~PROMPT
    Tu es un curateur musical expert et un DJ IA, appelé "Moody". Ton rôle est d'interpréter l'état d'esprit et l'activité de l'utilisateur pour lui fournir l'ambiance sonore idéale sur YouTube.

    --- CONTEXTE DE LA SESSION ---\nActivité : #{@chat.activity}, Mood : #{@chat.mood}, Durée : #{@chat.duration_minutes} minutes.

    --- RÈGLES DE FORMAT ---\nTon output doit toujours suivre deux parties : 1. Ta réponse textuelle. 2. UN BLOC DE CODE JSON STRICT à la fin, sans autre texte après. Le JSON DOIT contenir : {"ambiance_description": "...", "youtube_videos": [ {"title": "...", "url": "...", "video_id": "..."}, ... 5 au total ]}.
  PROMPT

  # Récupère tous les messages du chat, y compris l'historique
  messages = @chat.messages.order(created_at: :asc).map do |message|
    { role: message.role, content: message.content }
  end

  # Ajoute le System Prompt au début du tableau
  [{ role: "system", content: system_prompt_template }] + messages
end




#       messages_for_api = build_messages_for_api

#       client = OpenAI::Client.new

#       begin
#         response = client.chat(
#           parameters: {
#             model: "gpt-3.5-turbo",
#             messages: messages_for_api,
#             response_format: { type: "json_object" }
#           }
#         )

#         ai_content_json = response.choices.first.message.content
#         response_data = JSON.parse(ai_content_json)

#         @chat.messages.create!(
#           role: 'assistant',
#           content: response_data['ambiance_description']
#         )

#         response_data['youtube_videos'].each do |video|
#           @chat.musics.create!(
#             title: video['title'],
#             youtube_url: video['url'],
#             youtube_video_id: video['video_id'],
#           )
#         end

#         redirect_to chat_path(@chat)

#       rescue JSON::ParserError, NoMethodError => e
#         flash[:alert] = "Erreur: L'IA a généré une réponse invalide. Veuillez réessayer."
#         redirect_to chat_messages_path(@chat)
#       rescue => e
#         flash[:alert] = "Erreur lors de l'appel à l'API. Veuillez vérifier la configuration: #{e.message}"
#         redirect_to chat_messages_path(@chat)
#       end

#     else
#       @messages = @chat.messages.order(created_at: :asc)
#       render :index, status: :unprocessable_entity
#     end
#   end

#   private

#   def set_chat
#     @chat = Chat.find(params[:chat_id])
#   end

#   def message_params
#     params.require(:message).permit(:content)
#   end

#   def build_messages_for_api
#     system_prompt_template = <<~PROMPT
#       Tu es un curateur musical expert et un DJ IA, appelé "Moody". Ton rôle est d'interpréter l'état d'esprit et l'activité de l'utilisateur pour lui fournir l'ambiance sonore idéale sur YouTube.

#     --- CONTEXTE DE LA SESSION ---
#     Les paramètres actuels de la session sont : Activité : #{chat.activity}, Mood : #{chat.mood}, Durée : #{chat.duration_minutes} minutes.

#     --- RÈGLES DE FORMAT ---
#     Ton output doit toujours suivre deux parties : 1. Ta réponse textuelle. 2. UN BLOC DE CODE JSON STRICT à la fin, sans autre texte après. Le JSON DOIT contenir : {"title": "Titre court de l'ambiance", "videos": [ {"video_url": "URL_YOUTUBE_1"}, ... 5 au total ]}.
#   PROMPT


#     messages = @chat.messages.order(created_at: :asc).map do |message|
#       {
#         role: message.role,
#         content: message.content
#       }
#     end

#     messages.prepend({ role: 'system', content: system_prompt_template })
#     return messages
#   end
# end
