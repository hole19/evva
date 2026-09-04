module Evva
  class AnalyticsEvent
    attr_reader :event_name, :properties, :destinations, :platforms

    def initialize(event_name, properties, destinations, platforms = nil)
      @event_name = event_name
      @properties = properties
      @destinations = destinations
      @platforms = platforms
    end

    def supports_platform?(platform)
      return true if platforms.nil?

      platforms.include?(platform.to_s.downcase)
    end

    def ==(other)
      event_name == other.event_name &&
      properties == other.properties &&
      destinations == other.destinations &&
      platforms == other.platforms
    end
  end
end
