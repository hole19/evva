module Evva
  class AnalyticsEvent
    attr_reader :event_name, :properties, :destinations

    def initialize(event_name, properties, destinations)
      @event_name = event_name
      @properties = properties
      @destinations = destinations
    end

    def ==(other)
      event_name == other.event_name &&
      properties == other.properties &&
      destinations == other.destinations
    end
  end
end
