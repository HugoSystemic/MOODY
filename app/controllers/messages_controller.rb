class MessagesController < ApplicationController
  before_action :authenticate_user!

  SYSTEM_PROMPT_FOR_ACTIVITIES = "
    Can you find an activity and a duration depending on that message \n\n
    Please return a json format with this keys : { 'message'=> une réponse récapitulant les infos du message du user, 'activity'=> an activity, 'duration'=> a duration in seconds, 'found'=> true/false if you managed to find an activity and a duration, 'youtube_url'=> the direct YouTube video URL that match my mood, activity and duration, 'video_title'=> the title of the YouTube video }\n\n
    the key 'message' should return a message WITHOUT the youtube link (just the text)\n\n
    You should select a youtube video from the ten available"
  SYSTEM_PROMPT_YOUTUBE_API = "Using the activity and mood can you return me a text that I could use to search a youtube video, in the response I only want the text that I could copy/paste in the youtube search bar\n\n it should contains only music"
  SYSTEM_PROMPT_MUSIC_URLS = "
    Return a json format with these keys: { 'message'=> a text message (WITHOUT the youtube link), 'youtube_url'=> the direct YouTube video URL that match my mood, activity and duration, 'video_title'=> the title of the YouTube video, 'found'=>true/false if you found a video }\n\n
    You should select a youtube video from the ten available that is a music video and not some guide to do something"

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
      @ruby_llm_chat = RubyLLM.chat()
      build_conversation_history

      youtube_query = @ruby_llm_chat.with_instructions(SYSTEM_PROMPT_YOUTUBE_API).ask(@message.content).content
      youtube_tools = YoutubeTool.new(youtube_query, { max_results: 10 })

      parsed_response = askLLM()

      if parsed_response["found"] == true
        if @chat.messages.where(role: 'assistant').size == 1
          @chat.update(activity: parsed_response["activity"], duration: parsed_response["duration"])
        end

        @chat.messages.create(
          role: "assistant",
          content: parsed_response["message"],
          url_recommandation: parsed_response["youtube_url"]
        )

        create_music(parsed_response)
      end

      @chat.generate_title_from_first_message
      redirect_to @chat
    else
      render "chats/show", status: :unprocessable_entity
    end
  end

  private

  def ask_llm()
    response = @ruby_llm_chat.with_tools(youtube_tools).with_instructions(instructions()).ask(@message.content)
    JSON.parse(response.content)
  end

  def create_music(parsed_response)
    music = Music.create(
      category: "musique",
      duration_minutes: parsed_response["duration"],
      video_url: parsed_response["youtube_url"],
      title: parsed_response["video_title"],
      chat: @chat
    )
  end

  def message_params
    params.require(:message).permit(:content)
  end

  def build_conversation_history
    @chat.messages.each do |message|
      @ruby_llm_chat.add_message(message.slice(:role, :content))
    end
  end

  def instructions
    if @chat.messages.where(role: 'assistant').size == 1
      @ruby_llm_chat.with_instructions(SYSTEM_PROMPT_FOR_ACTIVITIES)
    else
      @ruby_llm_chat.with_instructions(SYSTEM_PROMPT_MUSIC_URLS + "\n\n" + "Choose a different video from the previous ones")
    end
  end
end
