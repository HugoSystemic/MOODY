class YoutubeTool < RubyLLM::Tool
  description "Gets youtube videos"

  # params do  # the params DSL is only available in v1.9+. older versions should use the param helper instead
  #   string :query, description: "Query to search videos (e.g., musique classique relaxante d'une heure)"
  #   hash :options, description: "Options to fine tune the query (e.g., limit)"
  # end

  def initialize(query, options = {})
    @query = query
    @options = options
  end

  def execute()
    YoutubeApiService.new().search(@query, @options)
  end
end
