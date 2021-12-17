module Evva
  class AnalyticsEvent
    attr_reader :event_name, :properties

    def initialize(event_name, properties)
      @event_name = event_name
      @properties = properties
    end

    def ==(other)
      event_name == other.event_name &&
      properties == other.properties
    end
  end
end
