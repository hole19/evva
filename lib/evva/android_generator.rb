module Evva
  class AndroidGenerator

    KOTLIN_EVENT_HEADER =  
    "package com.hole19golf.hole19.analytics\n"\
    "import com.hole19golf.hole19.analytics.Event\n\n"\
    "class MixpanelAnalytics(val mixpanelAPI: MixpanelAPI) {\n".freeze
    
    KOTLIN_PEOPLE_HEADER =  
    "package com.hole19golf.hole19.analytics\n"\
    "import com.hole19golf.hole19.analytics.Event\n\n"\
    "class PeopleProperties() {\n"\
    "\tcompanion object {\n".freeze

    def events(bundle)
      event_file = KOTLIN_EVENT_HEADER
      bundle.each do |event|
        event_file += kotlin_function(event)
      end
      event_file += "\n}"
    end

    def people_properties(people_bundle)
      properties = KOTLIN_PEOPLE_HEADER
      people_bundle.each do |prop|
        properties += kotlin_const(prop)
      end
      properties += "\t}\n }"
    end

    def kotlin_function(event_data)
      if !event_data.properties.nil?
        props = json_props(event_data.properties)
        function_body =
        "\nfun #{event_data.function_name}(#{event_data.properties}) {"\
        "#{props}"\
        "\tmixpanelApi.trackEvent('#{event_data.event_name}', properties)\n"
      else
        props = nil
        function_body =
        "\nfun #{event_data.function_name}(#{event_data.properties}) {\n"\
        "\tmixpanelApi.trackEvent('#{event_data.event_name}')\n"    
      end
      function_body += "}\n"
    end

    def kotlin_const(prop)
      people_property = "\t\tconst val #{prop.property_name} = '#{prop.property_value}'\n"
    end

    def kotlin_enum(enum)
      enum_body = "package com.hole19golf.hole19.analytics\n\n"
      enum_values = enum.values.split(',')
      enum_body += "enum class #{enum.enum_name}(val key: String) {\n"
      enum_values.each do |vals|
        enum_body += "\t#{vals.upcase}(" + "'#{vals}'" + "),\n"
      end
      enum_body += "} \n"
    end


    def json_props(properties)
      split_properties = ""
      properties.split(',').each do |prop|
        if is_special_property(prop)
          split_properties += "\t\tput('" + "#{prop.split(":").first()}', " + prop.split(":").first() + ")\n"
        else
          split_properties += "\t\tput('" + "#{prop.split(":").first()}', " + prop.split(":").first() + ".key)\n"
        end
      end
      resulting_json = "\n\tval properties = JSONObject().apply {\n" +
      +"#{split_properties}"
      resulting_json += "\n\t}\n"
    end

    def is_special_property(prop)
      types_array = ['Long', 'Integer','String', 'Double', 'Float']
      type = prop.split(':')[1]
      types_array.include?(type) ? true : false
    end
  end
end