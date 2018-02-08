module Evva
  class SwiftGenerator
    SWIFT_EVENT_HEADER =
      "import CoreLocation\n"\
      "import Foundation\n"\
      "import SharedCode\n\n"\
      "@objc class MixpanelHelper: NSObject {\n\n"\
      "\tprivate struct EventData {\n"\
      "\t\tlet name: String\n"\
      "\t\tlet properties: [String: Any]?\n"\
      "\t\tlet timeEvent: Bool\n\n"\
      "\t\tinit(name: String, properties: [String: Any]? = nil, timeEvent: Bool = false) {\n"\
      "\t\t\tself.name = name\n"\
      "\t\t\tself.properties = properties\n"\
      "\t\t\tself.timeEvent = timeEvent\n"\
      "\t\t}\n"\
      "\t}\n\n"\
      "\tenum Event {\n".freeze

    SWIFT_EVENT_DATA_HEADER =
      "\t\tprivate var data: EventData {\n"\
      "\t\t\tswitch self {\n".freeze

    SWIFT_PEOPLE_HEADER = "fileprivate enum Counter: String {\n".freeze

    SWIFT_INCREMENT_FUNCTION =
      "\tfunc increment(times: Int = 1) {\n"\
      "\t\tMixpanelAPI.instance.incrementCounter(rawValue, times: times)\n"\
      "\t}".freeze

    NATIVE_TYPES = %w[Int String Double Float Bool].freeze

    def events(bundle, file_name)
      event_file = SWIFT_EVENT_HEADER
      bundle.each do |event|
        event_file += swift_case(event)
      end
      event_file += SWIFT_EVENT_DATA_HEADER
      bundle.each do |event|
        event_file += swift_event_data(event)
      end
      event_file += "\t\t\t}\n"
      event_file += "\t\t}\n"
      event_file += "\t}\n"
      event_file += "}\n"
    end

    def swift_case(event_data)
      function_name = 'track' + titleize(event_data.event_name)
      if event_data.properties.empty?
        "\t\tcase #{function_name}\n"
      else
        trimmed_properties = event_data.properties.map { |k, v| k.to_s + ': ' + native_type(v) }.join(", ")
        "\t\tcase #{function_name}(#{trimmed_properties})\n"
      end
    end

    def swift_event_data(event_data)
      function_name = 'track' + titleize(event_data.event_name)
      if event_data.properties.empty?
        function_body = "\t\t\tcase .#{function_name}:\n" \
                        "\t\t\t\treturn EventData(name: \"#{event_data.event_name}\")\n\n"
      else
        function_header = prepend_let(event_data.properties)
        function_arguments = dictionary_pairs(event_data.properties)
        function_body = "\t\t\tcase .#{function_name}(#{function_header}):\n"\
                        "\t\t\t\treturn EventData(name: \"#{event_data.event_name}\", properties: [\n"\
                        "\t\t\t\t\t#{function_arguments.join(",\n\t\t\t\t\t")} ]\n"\
                        "\t\t\t\t)\n\n"
      end
      function_body
    end

    def event_enum(enum, file_name)
      # empty
    end

    def people_properties(people_bundle, file_name)
      properties = SWIFT_PEOPLE_HEADER
      properties += people_bundle.map { |prop| swift_people_const(prop) }.join('')
      properties + "\n" + SWIFT_INCREMENT_FUNCTION + "\n}\n"
    end

    def special_property_enum(enum)
      enum_body = "import Foundation\n\n"
      enum_body += "enum #{enum.enum_name}: String {\n"
      enum_body += enum.values.map { |vals| "\tcase #{vals.tr(' ', '_')} = \"#{vals}\"\n" }.join('')
      enum_body + "} \n"
    end

    def dictionary_pairs(props)
      props.map do |name, type|
        pair = "\"#{name}\": #{name}"
        if is_raw_representable_property?(type)
          if is_optional_property?(type)
            pair += "?"
          end
          pair += ".rawValue"
        end
        pair += " as Any"
      end
    end

    private

    def is_raw_representable_property?(type)
      !NATIVE_TYPES.include?(native_type(type).chomp('?'))
    end

    def is_optional_property?(type)
      type.end_with?('?')
    end

    def native_type(type)
      type.gsub('Boolean','Bool').gsub('Long', 'Int')
    end

    def prepend_let(props)
      props.map { |k, v| "let #{k}" }.join(', ')
    end

    def swift_people_const(prop)
      "\tcase #{titleize(prop)} = \"#{prop}\"\n"
    end

    def titleize(str)
      str.split('_').collect(&:capitalize).join
    end
  end
end
