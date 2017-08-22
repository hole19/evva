module Evva
    class MixpanelEvent

        attr_reader :functionName, :eventName, :properties
        def initialize(functionName, eventName, properties)
            @functionName = functionName
            @eventName = eventName
            @properties = !properties.empty? ? properties : nil
        end

        def ==(another_event)
            self.functionName == another_event.functionName
            self.eventName == another_event.eventName
        end
    end  
end