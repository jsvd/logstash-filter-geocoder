# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"

class LogStash::Filters::Geocoder < LogStash::Filters::Base

  config_name "geocoder"

  # field containing the content to be searched
  config :source, :validate => :string, :default => "message"

  # target field to set the coordinates
  config :target, :validate => :string, :default => "geo"

  # geocoder search provider
  config :lookup, :validate => ["yandex", "google"], :default => "google"

  # geocoder search provider
  config :cache_size, :validate => :number, :default => 0

  public
  def register
    require "geocoder"
    Geocoder.configure(:lookup => @lookup.to_sym)
    if @cache_size > 0
      Geocoder.configure(:cache => LruRedux::ThreadSafeCache.new(@cache_size))
    end
  end # def register

  public
  def filter(event)
    begin
      coordinates = Geocoder.coordinates(event[@source])
    rescue => e
      event.tag("_geocode_failure")
      return
    end

    if coordinates
      event[@target] = coordinates
      filter_matched(event)
    else
      event.tag("_geocode_notfound")
    end
  end # def filter
end # class LogStash::Filters::Geocoder
