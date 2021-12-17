module Evva
  class AnalyticsEvent
    attr_reader :event_name, :properties, :platforms

    def initialize(event_name, properties, platforms)
      @event_name = event_name
      @properties = properties
      @platforms = platforms
    end

    def ==(other)
      event_name == other.event_name &&
      properties == other.properties &&
      platforms == other.platforms
    end
  end
end
