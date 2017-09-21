module Evva
  class SwiftGenerator

    SWIFT_EVENT_HEADER =
    "import CoreLocation\n"\
    "import Foundation\n"\
    "import SharedCode\n\n"\
    "class MixpanelHelper: NSObject {\n"\
    "enum Event {\n"

    SWIFT_EVENT_DATA_HEADER =
    "private var data: EventData {\n"\
    "switch self {\n\n\n"

    SWIFT_PEOPLE_HEADER = "fileprivate enum Counter: String {\n".freeze

    SWIFT_INCREMENT_FUNCTION =
            "func increment(times: Int = 1) {\n"\
            "MixpanelAPI.instance.incrementCounter(rawValue, times: times)\n"\
            "}"

    def events(bundle)
      event_file = SWIFT_EVENT_HEADER
      bundle.each do |event|
        event_file += swift_case(event)
      end
      event_file += "}\n"
      event_file += "private var data: EventData {\n"\
      "switch self {\n\n"
      bundle.each do |event|
        event_file += swift_event_data(event)
      end
      event_file += "}\n}\n"
    end

    def swift_case(event_data)
      if event_data.properties.nil?
        case_body = "\t\tcase #{event_data.function_name}\n"
      else
        trimmed_properties = event_data.properties.gsub("Boolean", "Bool")
        case_body = "\t\tcase #{event_data.function_name}(#{trimmed_properties})\n"
      end
    end

    def swift_event_data(event_data)
      if event_data.properties.nil?
        function_body = "case .#{event_data.function_name} \n" +
        "\treturn EventData(name:" + %Q{"#{event_data.event_name}"} + ")\n\n"
      else
        function_header = prepend_let(event_data.properties)
        function_arguments = process_arguments(event_data.properties.gsub("Boolean", "Bool"))
        function_body = "case .#{event_data.function_name}(#{function_header}):\n" +
        "\treturn EventData(name:" + %Q{"#{event_data.event_name}"} + ", properties: [#{function_arguments}])\n\n"
      end

      function_body
    end

    def event_enum(enum)
      # empty
    end

    def people_properties(people_bundle)
      properties = SWIFT_PEOPLE_HEADER
      people_bundle.each do |prop|
        properties += swift_people_const(prop)
      end
      properties += SWIFT_INCREMENT_FUNCTION + "\n}"
    end

    def swift_people_const(prop)
      case_body = "\tcase #{prop.property_name} = " + %Q{"#{prop.property_value}"} + "\n"
    end

    def special_property_enum(enum)
      enum_body = "import Foundation\n\n"
      enum_values = enum.values.split(',')
      enum_body += "enum #{enum.enum_name}: String {\n"
      enum_values.each do |vals|
        enum_body += "\tcase #{vals.tr(" ","_")} = " + %Q{"#{vals}"} + "\n"
      end
      enum_body += "} \n"
    end

    def prepend_let(props)
      function_header = ""
      props.split(',').each do |property|
        function_header += "let " + property.split(':')[0] + ", "
      end
      function_header.chomp(', ')
    end

    def process_arguments(props)
      arguments = ""
      props.split(',').each do |property|
        if is_special_property(property)
          if is_optional_property(property)

          else
            arguments += %Q{"#{property.split(":").first}"} + ":" + property.split(":").first + ".rawValue, "
          end
        else
          arguments += %Q{"#{property.split(":").first}"} + ":" + property.split(":").first + ", "
        end
      end
      arguments.chomp(', ')
    end

    def is_special_property(prop)
      types_array = ['Long', 'Int','String', 'Double', 'Float', 'Boolean']
      type = prop.split(':')[1]
      types_array.include?(type) ? false : true
    end

    def is_optional_property(prop)
      type = prop.split(':')[1]
      type.include?("?") ? true : false
    end
  end
end