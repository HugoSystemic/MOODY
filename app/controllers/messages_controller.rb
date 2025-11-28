class MessagesController < ApplicationController
  before_action :authenticate_user!
  # before_action :set_chat

  SYSTEM_PROMPT_FOR_ACTIVITIES = "Can you find an activity and a duration depending on that message \n\n Please return a json format with this keys : { 'message'=> une réponse récapitulant les infos du message du user, 'activity'=> an activity, 'duration'=> a duration in minutes, 'found'=> true/false if you managed to find an activity and a duration, 'youtube_url'=> the direct YouTube video URL that match my mood, activity and duration, 'video_title'=> the title of the YouTube video }\n\n the key 'message' should return a message WITHOUT the youtube link (just the text)\n\n check that the video is still accessible"
  SYSTEM_PROMPT_MUSIC_URLS = "Return a json format with these keys: { 'message'=> a text message (WITHOUT the youtube link), 'youtube_url'=> the direct YouTube video URL that match my mood, activity and duration, 'video_title'=> the title of the YouTube video }\n\n check that the video is still accessible on youtube"

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
    @message.role = 'user'

    if @message.save
      @ruby_llm_chat = RubyLLM.chat
      build_conversation_history

      if @chat.messages.where(role: 'assistant').size == 1
        response = @ruby_llm_chat.with_instructions(SYSTEM_PROMPT_FOR_ACTIVITIES).ask(@message.content)
        parsed_response = JSON.parse(response.content)
        if parsed_response["found"] == true
          @chat.update(activity: parsed_response["activity"], duration: parsed_response["duration"])
          @chat.messages.create(
            role: "assistant",
            content: parsed_response["message"],
            url_recommandation: parsed_response["youtube_url"])

            create_music(parsed_response)
        end

      else
        response = @ruby_llm_chat.with_instructions(SYSTEM_PROMPT_MUSIC_URLS).ask(@message.content)
        @chat.messages.create(
          role: "assistant",
          content: response.content,
          url_recommandation: parsed_response["youtube_url"]
        )
      end

      @chat.generate_title_from_first_message
      redirect_to @chat
    else
      render "chats/show", status: :unprocessable_entity
    end
  end

  private

  def create_music(parsed_response)
    music = Music.new(
      category: "musique",
      duration_minutes: parsed_response["duration"],
      video_url: parsed_response["youtube_url"],
      title: parsed_response["video_title"]
    )

      music.chat = @chat
      music.save


  end

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
