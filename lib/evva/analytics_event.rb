module Evva
  class AnalyticsEvent
    # Concrete platforms an event can be generated for, in canonical order.
    PLATFORMS = %w[android ios].freeze

    attr_reader :event_name, :properties, :destinations, :platforms

    def initialize(event_name, properties, destinations, platforms = PLATFORMS)
      @event_name = event_name
      @properties = properties
      @destinations = destinations
      @platforms = platforms
    end

    def supports_platform?(platform)
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
