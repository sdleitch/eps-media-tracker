# require "nokogiri"
# require "sanitize"
# require "open-uri"
# require "sequel"

DB = Sequel.connect(ENV['DATABASE_URL'])

DB.create_table? :mediareleases do
  primary_key :id
  String :title
  String :link
  DateTime :datetime
  String :content
  String :mru
  String :contact
end

media_releases = DB[:mediareleases]

EPS_RSS_URI = "http://www.edmontonpolice.ca/News/MediaReleases.aspx?RSS=1"

class MediaRelease
  attr_reader(:title, :link, :datetime, :content, :mru, :contact)

  def initialize(title, link, datetime, content, mru, contact)
    @title = title
    @link = link
    @datetime = datetime
    @content = content
    @mru = mru
    @contact = contact
  end
end

response = Nokogiri::XML(open(EPS_RSS_URI)) do |config|
  config.strict.noblanks
end

releases = response.css("item link")

scraped_releases = []

releases.each do |r|
  uri = r.content
  page = Nokogiri::HTML(open(uri))
  release_body = page.at_css("#mediaRelease")

  title = release_body.at_css("h1").content.strip

  datetime_string = release_body.at_css("#date").content.strip
  datetime = DateTime.parse(datetime_string)

  mru = release_body.at_css("#MRU").content.strip
  mru.gsub!("MRU #:", "")

  content_raw = release_body.at_css("#content").content.strip
  content = Sanitize.fragment(content_raw).squeeze(" ")

  contact = release_body.at_css("#contact").content.strip

  scraped_releases << MediaRelease.new(
    title,
    uri,
    datetime,
    content,
    mru,
    contact
  )
end

scraped_releases.each do |r|
  query = media_releases.where(mru: r.mru)
  if query.count == 0
    media_releases.insert(
      title: r.title,
      link: r.link,
      datetime: r.datetime,
      content: r.content,
      mru: r.mru,
      contact: r.contact
    )
  end
end
