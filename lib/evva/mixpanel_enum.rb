module Evva
    class MixpanelEnum

        attr_reader :enumName, :values
        def initialize(enumName, values)
            @enumName = enumName
            @values = values
        end

        def ==(another_enum)
            self.enumName == another_enum.enumName
            self.values == another_enum.values
        end

    end  
end