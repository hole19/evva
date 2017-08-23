module Evva
  class MixpanelEvent

    attr_reader :function_name, :event_name, :properties
    def initialize(function_name, event_name, properties)
      @function_name = function_name
      @event_name = event_name
      @properties = !properties.empty? ? properties : nil
    end

    def ==(other)
      self.function_name == other.function_name
      self.event_name == other.event_name
    end
  end
end