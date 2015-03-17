require 'spec_helper'
require "logstash/filters/geocoder"
require "geocoder"
require 'lru_redux'

describe LogStash::Filters::Geocoder do

  config <<-CONFIG
    filter {
      geocoder { }
    }
  CONFIG

  sample "Lisbon, Portugal" do
    expect(Geocoder).to receive(:coordinates).with("Lisbon, Portugal")
    insist { subject["geo"] }.nil?
  end

  context "when the location doesn't exist" do
    sample "Endor" do
      expect(Geocoder).to receive(:coordinates).with("Endor").and_return(nil)
      insist { subject["tags"] } == ["_geocode_notfound"]
    end
  end

  context "when search raises an exception" do
    sample "Lisbon" do
      expect(Geocoder).to receive(:coordinates).and_raise RuntimeError
      insist { subject["tags"] } == ["_geocode_failure"]
    end
  end

  context "when using lru_cache" do
    cache_size = 2
    cache_class = ::LruRedux::ThreadSafeCache
    config <<-CONFIG
      filter {
        geocoder { cache_size => #{cache_size} }
      }
    CONFIG
    sample ["Lisbon, Portugal"] * 2 do
      cache = cache_class.new(cache_size)
      expect(cache_class).to receive(:new).with(cache_size).and_return(cache)
      expect(cache).to receive(:[]=).once.and_call_original
      insist { subject.size } == 2
    end
  end
end
