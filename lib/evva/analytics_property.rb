module Evva
  class AnalyticsProperty
    attr_reader :property_name, :type, :destinations

    def initialize(property_name, type, destinations)
      @property_name = property_name
      @type = type
      @destinations = destinations
    end

    def ==(other)
      property_name == other.property_name &&
      type == other.type &&
      destinations == other.destinations
    end
  end
end
