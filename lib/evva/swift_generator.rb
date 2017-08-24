module Evva
  class SwiftGenerator

    attr_reader :path
    def initialize(path)
      @path = path
    end

    def events(bundle)
      bundle.each do |event|
        event_file += swift_function(event)
      end   
    end

    def swift_function(event_data)
      function_body = "case .#{event_data.function_name}(): \n" + 
      "return EventData(name:" + "'#{event_data.event_name}'" + ", properties: [#{event_data.properties}]\n"
      function_body
    end

    def swift_enum(enum)
      enum_values = enum.values.split(',')
      enum_body = "enum #{enum.enum_name}: String {\n"
      enum_values.each do |vals|
        enum_body += "\tcase #{vals} = "+ "'#{vals}'" + "\n"
      end
      enum_body += "} \n"
    end

  end
end