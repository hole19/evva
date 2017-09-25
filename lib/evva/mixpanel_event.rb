module Evva
  class MixpanelEvent
    attr_reader :event_name, :properties
    def initialize(event_name, properties)
      @event_name = event_name
      @properties = !properties.empty? ? properties : nil
    end

    def ==(other)
      event_name == other.event_name
    end
  end
end
