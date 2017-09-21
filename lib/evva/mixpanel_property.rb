module Evva
  class MixpanelProperty
    attr_reader :property_name, :property_value
    def initialize(property_name, property_value)
      @property_name = property_name
      @property_value = property_value
    end

    def ==(other)
      property_name == other.property_name
      property_value == other.property_value
    end
  end
end
