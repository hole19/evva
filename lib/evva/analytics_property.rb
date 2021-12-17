module Evva
  class AnalyticsProperty
    attr_reader :property_name, :type

    def initialize(property_name, type)
      @property_name = property_name
      @type = type
    end

    def ==(other)
      property_name == other.property_name &&
      type == other.type
    end
  end
end
