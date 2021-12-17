module Evva
  class AnalyticsProperty
    attr_reader :property_name, :type, :platforms

    def initialize(property_name, type, platforms)
      @property_name = property_name
      @type = type
      @platforms = platforms
    end

    def ==(other)
      property_name == other.property_name &&
      type == other.type &&
      platforms == other.platforms
    end
  end
end
