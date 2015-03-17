# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"

class LogStash::Filters::Geocoder < LogStash::Filters::Base

  config_name "geocoder"

  # field containing the content to be searched
  config :source, :validate => :string, :default => "message"

  # target field to set the coordinates
  config :target, :validate => :string, :default => "geo"

  # geocoder search provider. choose yandex or google
  # others can be supported if an api key config is added
  config :lookup, :validate => ["yandex", "google"], :default => "google"

  # cache a certain amount of search results. 0 to disable
  # uses a LRU cache library: https://github.com/SamSaffron/lru_redux
  config :cache_size, :validate => :number, :default => 0

  public
  def register
    require "geocoder"
    Geocoder.configure(:lookup => @lookup.to_sym)
    if @cache_size > 0
      require 'lru_redux'
      Geocoder.configure(:cache => ::LruRedux::ThreadSafeCache.new(@cache_size))
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
