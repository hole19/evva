module Evva
  class AndroidGenerator
    KOTLIN_EVENT_HEADER =
      "package com.hole19golf.hole19.analytics\n\n"\
      "import com.hole19golf.hole19.analytics.Event\n"\
      "import com.hole19golf.hole19.analytics.MixpanelAnalyticsMask\n"\
      "import org.json.JSONObject\n\n"\
      "open class MixpanelEvents(private val mixpanelMask: MixpanelAnalyticsMask) {\n".freeze

    KOTLIN_PEOPLE_HEADER =
      "package com.hole19golf.hole19.analytics\n"\
      "import com.hole19golf.hole19.analytics.Event\n\n"\
      "enum class MixpanelProperties(val key: String) {\n".freeze

    KOTLIN_BUNDLE_HEADER =
      "package com.hole19golf.hole19.analytics\n"\
      "import com.hole19golf.hole19.analytics.Event\n\n"\
      "enum class MixpanelEvent(override val key: String) : Event {\n".freeze

    KOTIN_PEOPLE_FUNCTIONS =
      "\topen fun updateProperties(property: MixpanelProperties, value: Any) {\n"\
      "\t\tmixpanelMask.updateProperties(property.key, value)"\
      "\t\n} \n"\
      "\topen fun incrementCounter(property: MixpanelProperties) {\n"\
      "\t\tmixpanelMask.incrementCounter(property.key)"\
      "\t\n} \n".freeze

    NATIVE_TYPES = %w[Long Int String Double Float Boolean].freeze

    def events(bundle)
      event_file = KOTLIN_EVENT_HEADER
      bundle.each do |event|
        event_file += "\n#{kotlin_function(event)}"
      end
      event_file += KOTIN_PEOPLE_FUNCTIONS
      event_file += "\n}"
    end

    def people_properties(people_bundle)
      properties = KOTLIN_PEOPLE_HEADER
      properties += people_bundle.map do |prop| "\t\t#{prop.upcase}(" + %("#{prop}") + ")" end.join(",\n")
      properties += ";\n}\n"
    end

    def event_enum(bundle)
      event_file = KOTLIN_BUNDLE_HEADER
      event_file += bundle.map do |event| "\t\t#{event.event_name.upcase}(" + %("#{event.event_name}") + ")" end.join(", \n")
      event_file += "\n}\n"
    end

    def kotlin_function(event_data)
      function_name = 'track' + titleize(event_data.event_name)
      function_arguments = event_data.properties.map { |name, type| "#{name.to_s}: #{type}" }.join(', ')
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
      enum_body += enum.values.map do |vals| "\t#{vals.tr(' ', '_').upcase}(" + %("#{vals}") + ")" end.join(",\n")
      enum_body += "\n}\n"
    end

    private

    def kotlin_people_const(prop)
      people_property = "\t\t#{prop.upcase}(" + %("#{prop}") + ")\n"
    end

    def kotlin_event_const(event)
      kotlin_event = "\t\t#{event.event_name.upcase}(" + %("#{event.event_name}") + "),\n"
    end

    def json_props(properties)
      split_properties = ''
      split_properties += properties.map { |name, type|
        if special_property?(type)
          if optional_property?(type)
             "" + name.to_s + '?.let { put(' + %("#{name}") + ", it.key) }"
          else
            "" + 'put(' + %("#{name}") + ", #{name.to_s}.key)"
          end
        else
          if optional_property?(type)
            "" + name.to_s + '?.let { put(' + %("#{name}") + ", it) }"
          else
            "put(" + %("#{name}") + ', ' + name.to_s + ")"
          end
        end
       }
       .map{ |line| "\t\t" + line }
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
