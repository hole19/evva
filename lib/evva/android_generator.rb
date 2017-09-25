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
      "\t\tmixpanelMask.setProperty(property.key value)"\
      "\t\n} \n"\
      "\topen fun incrementCounter(property: MixpanelProperties) {\n"\
      "\t\tmixpanelMask.incrementCounter(property.key, value)"\
      "\t\n} \n".freeze

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
      people_bundle.each do |prop|
        properties += kotlin_people_const(prop)
      end
      properties += "}\n"
    end

    def event_enum(bundle)
      event_file = KOTLIN_BUNDLE_HEADER
      bundle.each do |event|
        event_file += kotlin_event_const(event)
      end
      event_file += "\n}\n"
    end

    def kotlin_function(event_data)
      function_name = 'track' + titleize(event_data.event_name)
      if !event_data.properties.nil?
        props = json_props(event_data.properties)
        function_body =
          "open fun #{function_name}(#{event_data.properties}) {"\
          "#{props}"\
          "\tmixpanelMask.trackEvent(MixpanelEvent.#{event_data.event_name.upcase}, properties)\n"
      else
        props = nil
        function_body =
          "open fun #{function_name}(#{event_data.properties}) {\n"\
          "\tmixpanelMask.trackEvent(MixpanelEvent.#{event_data.event_name.upcase})\n"
      end
      function_body += "}\n"
    end

    def special_property_enum(enum)
      enum_body = "package com.hole19golf.hole19.analytics\n\n"
      enum_values = enum.values.split(',')
      enum_body += "enum class #{enum.enum_name}(val key: String) {\n"
      enum_values.each do |vals|
        enum_body += "\t#{vals.tr(' ', '_').upcase}(" + %("#{vals}") + "),\n"
      end
      enum_body += "} \n"
    end

    private

    def kotlin_people_const(prop)
      capitalized_property = titleize(prop)
      people_property = "\t\tval #{capitalized_property} = " + %("#{prop}") + "\n"
    end

    def kotlin_event_const(event)
      kotlin_event = "\t\t#{event.event_name.upcase}(" + %("#{event.event_name}") + "),\n"
    end

    def json_props(properties)
      split_properties = ''
      properties.split(',').each do |prop|
        if is_special_property(prop)
          if is_optional_property(prop)
            split_properties += "\t\t" + prop.split(':').first + '?.let { put(' + %("#{prop.split(':').first}") + ", it.key)}\n"
          else
            split_properties += "\t\tput(" + %("#{prop.split(':').first}") + ', ' + prop.split(':').first + ".key)\n"
         end
        else
          split_properties += "\t\tput(" + %("#{prop.split(':').first}") + ', ' + prop.split(':').first + ")\n"
        end
      end
      resulting_json = "\n\tval properties = JSONObject().apply {\n" +
                       +split_properties.to_s
      resulting_json += "\n\t}\n"
    end

    def is_special_property(prop)
      types_array = %w[Long Int String Double Float Boolean]
      type = prop.split(':')[1]
      types_array.include?(type) ? false : true
    end

    def is_optional_property(prop)
      type = prop.split(':')[1]
      type.include?('?') ? true : false
    end

    def titleize(str)
      str.split('_').collect(&:capitalize).join
    end
  end
end
