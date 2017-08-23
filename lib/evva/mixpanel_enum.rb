module Evva
  class MixpanelEnum

    attr_reader :enum_name, :values
    def initialize(enum_name, values)
      @enum_name = enum_name
      @values = values
    end

    def ==(other)
      self.enum_name == other.enum_name
      self.values == other.values
    end
  end
end