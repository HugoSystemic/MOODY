module ApplicationHelper
  def extract_youtube_id(url)
    return nil unless url.present?

    regex = %r{(?:youtube\.com/(?:[^/]+/.+/|(?:v|e(?:mbed)?)/|.*[?&]v=)|youtu\.be/)([^"&?/\s]{11})}
    match = url.match(regex)
    match ? match[1] : nil
  end
end
