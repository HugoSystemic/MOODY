require 'net/http'
require 'uri'

class YoutubeApiService
  def initialize
    @base_url = 'https://www.googleapis.com/youtube/v3'
    @api_key = ENV["YOUTUBE_API_KEY"]
    raise 'YOUTUBE_API_KEY not configured' if @api_key.blank?
  end

  def search(query, options = {})
    max_results = options[:max_results] || 10
    order = options[:order] || 'relevance'
    page_token = options[:page_token]

    params = build_search_params(query, max_results, order, page_token)
    response = make_request('/search', params)

    return response if response[:error]

    {
      videos: format_search_results(response['items'] || []),
      next_page_token: response['nextPageToken'],
      prev_page_token: response['prevPageToken'],
      total_results: response.dig('pageInfo', 'totalResults')
    }
  end

  private

  def build_search_params(query, max_results, order, page_token)
    params = {
      part: 'snippet',
      q: query,
      maxResults: max_results,
      order: order,
      type: 'video',
      key: @api_key
    }
    params[:pageToken] = page_token if page_token
    params
  end

  def make_request(endpoint, params)
    query_string = URI.encode_www_form(params)
    url = "#{@base_url}#{endpoint}?#{query_string}"
    uri = URI.parse(url)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 10
    http.open_timeout = 5

    request = Net::HTTP::Get.new(uri.request_uri)
    request['Accept'] = 'application/json'

    response = http.request(request)

    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)
    else
      handle_error_response(response)
    end
  rescue StandardError => e
    Rails.logger.error("YouTube API Error: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    { error: e.message }
  end

  def handle_error_response(response)
    error_data = JSON.parse(response.body) rescue {}
    error_message = error_data.dig('error', 'message') || 'API request failed'
    error_code = response.code

    Rails.logger.error("YouTube API Error (#{error_code}): #{error_message}")

    { error: error_message, status_code: error_code }
  end

  def format_search_results(items)
    items.map do |item|
      {
        video_id: item.dig('id', 'videoId'),
        title: item.dig('snippet', 'title'),
        description: item.dig('snippet', 'description'),
        channel_title: item.dig('snippet', 'channelTitle'),
        channel_id: item.dig('snippet', 'channelId'),
        published_at: item.dig('snippet', 'publishedAt'),
        thumbnail_default: item.dig('snippet', 'thumbnails', 'default', 'url'),
        thumbnail_medium: item.dig('snippet', 'thumbnails', 'medium', 'url'),
        thumbnail_high: item.dig('snippet', 'thumbnails', 'high', 'url'),
        url: "https://www.youtube.com/watch?v=#{item.dig('id', 'videoId')}"
      }
    end
  end
end
