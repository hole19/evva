module Evva
  class AndroidGenerator
    KOTLIN_EVENT_HEADER =
      "package com.hole19golf.hole19.analytics\n\n"\
      "import com.hole19golf.hole19.analytics.Event\n"\
      "import com.hole19golf.hole19.analytics.MixpanelAnalyticsMask\n"\
      "import org.json.JSONObject\n\n".freeze

    KOTLIN_PEOPLE_HEADER =
      "package com.hole19golf.hole19.analytics\n"\
      "import com.hole19golf.hole19.analytics.Event\n\n".freeze

    KOTLIN_BUNDLE_HEADER =
      "package com.hole19golf.hole19.analytics\n"\
      "import com.hole19golf.hole19.analytics.Event\n\n".freeze

    KOTIN_PEOPLE_FUNCTIONS =
      "\nopen fun updateProperties(property: MixpanelProperties, value: Any) {\n"\
      "\t\tmixpanelMask.updateProperties(property.key, value)"\
      "\t\n} \n"\
      "\nopen fun incrementCounter(property: MixpanelProperties) {\n"\
      "\t\tmixpanelMask.incrementCounter(property.key)"\
      "\t\n} \n".freeze

    NATIVE_TYPES = %w[Long Int String Double Float Boolean].freeze

    def events(bundle, file_name)
      event_file = KOTLIN_EVENT_HEADER + "open class #{file_name}(private val mixpanelMask: MixpanelAnalyticsMask) {\n".freeze
      bundle.each do |event|
        event_file += "\n#{kotlin_function(event)}"
      end
      event_file += KOTIN_PEOPLE_FUNCTIONS
      event_file += "\n}"
    end

    def people_properties(people_bundle, file_name)
      properties = KOTLIN_PEOPLE_HEADER + "enum class #{file_name}(val key: String) {\n"
      properties += people_bundle.map { |prop| "\t\t#{prop.upcase}(\"#{prop}\")" }.join(",\n")
      properties += ";\n}\n"
    end

    def event_enum(bundle, file_name)
      event_file = KOTLIN_BUNDLE_HEADER + "enum class #{file_name}(override val key: String) : Event {\n"
      event_file += bundle.map { |event| "\t\t#{event.event_name.upcase}(\"#{event.event_name}\")"}.join(", \n")
      event_file += "\n}\n"
    end

    def kotlin_function(event_data)
      function_name = 'track' + titleize(event_data.event_name)
      function_arguments = event_data.properties.map { |name, type| "#{name}: #{type}" }.join(', ')
      if !function_arguments.empty?
        props = json_props(event_data.properties)
        function_body =
          "open fun #{function_name}(#{function_arguments}) {"\
          "#{props}"\
          "\tmixpanelMask.trackEvent(MixpanelEvent.#{event_data.event_name.upcase}, properties)\n"
      else
        function_body =
          "open fun #{function_name}() {\n"\
          "\tmixpanelMask.trackEvent(MixpanelEvent.#{event_data.event_name.upcase})\n"
      end
      function_body += "}\n"
    end

    def special_property_enum(enum)
      enum_body = "package com.hole19golf.hole19.analytics\n\n"
      enum_body += "enum class #{enum.enum_name}(val key: String) {\n"
      enum_body += enum.values.map { |vals| "\t#{vals.tr(' ', '_').upcase}(\"#{vals}\")"}.join(",\n")
      enum_body += "\n}\n"
    end

    private

    def json_props(properties)
      split_properties =
        properties
        .map do |name, type|
          if special_property?(type)
            if optional_property?(type)
              "#{name}?.let { put(\"#{name}\", it.key) }"
            else
              "put(\"#{name}\", #{name}.key)"
            end
          else
            if optional_property?(type)
              "#{name}?.let { put(\"#{name}\", it) }"
            else
              "put(\"#{name}\", #{name})"
            end
          end
        end
        .map { |line| "\t\t#{line}" }
        .join("\n")

      resulting_json = "\n\tval properties = JSONObject().apply {\n" +
                       +split_properties.to_s
      resulting_json += "\n\t}\n"
    end

    def special_property?(type)
      !NATIVE_TYPES.include?(type.chomp('?'))
    end

    def optional_property?(type)
      type.include?('?')
    end

    def titleize(str)
      str.split('_').collect(&:capitalize).join
    end
  end
end
