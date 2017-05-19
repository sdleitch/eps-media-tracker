# require "nokogiri"
# require "sanitize"
# require "open-uri"
require "sequel"

DB = Sequel.connect(ENV['DATABASE_URL']) 

class MediaReleaseServer
  def call(env)
    [200, {"Content-Type" => "text/html"}, [get_recent_releases]]
  end

  def get_recent_releases(days=5)
    releases = DB[:mediareleases].where(datetime: (DateTime.now - days)..(DateTime.now))
    response = "<!DOCTYPE html><head><meta charset=\"utf-8\"><title></title></head><body>"
    releases.each do |r|
      response +=
      "<h1>#{r[:title]}</h1>
      <h2>#{r[:datetime]}</h2>
      <p>#{r[:mru]}</p>
      #{r[:content]}
      <p>#{r[:contact]}
      <br><br>"
    end
    response += "</body>"
    return response
  end
end
