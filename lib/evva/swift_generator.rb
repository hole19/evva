module Evva
  class SwiftGenerator
    SWIFT_EVENT_HEADER =
      "import CoreLocation\n"\
      "import Foundation\n"\
      "import SharedCode\n\n"\
      "class MixpanelHelper: NSObject {\n"\
      "\tenum Event {\n".freeze

    SWIFT_EVENT_DATA_HEADER =
      "\t\tprivate var data: EventData {\n"\
      "\t\t\tswitch self {\n".freeze

    SWIFT_PEOPLE_HEADER = "fileprivate enum Counter: String {\n".freeze

    SWIFT_INCREMENT_FUNCTION =
      "func increment(times: Int = 1) {\n"\
      "MixpanelAPI.instance.incrementCounter(rawValue, times: times)\n"\
      '}'.freeze

    NATIVE_TYPES = %w[Long Int String Double Float Bool].freeze

    def events(bundle, file_name)
      event_file = SWIFT_EVENT_HEADER
      bundle.each do |event|
        event_file += swift_case(event)
      end
      event_file += "}\n"
      event_file += SWIFT_EVENT_DATA_HEADER
      bundle.each do |event|
        event_file += swift_event_data(event)
      end
      event_file += "}\n}\n"
    end

    def swift_case(event_data)
      function_name = 'track' + titleize(event_data.event_name)
      if event_data.properties.empty?
        "\t\tcase #{function_name}\n"
      else
        trimmed_properties = event_data.properties.map { |k, v| k.to_s + '": ' + v.gsub('Boolean', 'Bool') }.join(",\"")
        "\t\tcase #{function_name}(\"#{trimmed_properties})\n"
      end
    end

    def swift_event_data(event_data)
      function_name = 'track' + titleize(event_data.event_name)
      if event_data.properties.empty?
        function_body = "\t\t\tcase .#{function_name} \n" \
                        "\t\t\t\treturn EventData(name:\"#{event_data.event_name}\")\n\n"
      else
        function_header = prepend_let(event_data.properties)
        function_arguments = process_arguments(event_data.properties.map { |k, v| "#{k}: #{v.gsub('Boolean', 'Bool')}" })
        function_body = "\t\t\tcase .#{function_name}(#{function_header}):\n" \
                        "\t\t\t\treturn EventData(name:\"#{event_data.event_name}\", properties: [#{function_arguments}])\n\n"
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

    def process_arguments(props)
      arguments = ''
      props.each do |property|
        val = property.split(':').first
        if is_special_property?(property)
          if is_optional_property?(property)
            val = val.chomp('?')
            arguments += "\"#{val}\": #{val}.rawValue, "
          else
            arguments += "\"#{val}\": #{val}.rawValue, "
          end
        else
          if is_optional_property?(property)
            val = val.chomp('?')
            arguments += "\"#{val}\": #{val}, "
          else
            arguments += "\"#{val}\": #{val}, "
          end
        end
      end
      arguments.chomp(', ')
    end

    private

    def is_special_property?(prop)
      type = prop.split(':')[1]
      !NATIVE_TYPES.include?(type.chomp('?'))
    end

    def is_optional_property?(prop)
      type = prop.split(':')[1]
      type.include?('?') ? true : false
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
