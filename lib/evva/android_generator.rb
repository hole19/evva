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
    "class PeopleProperties() {\n"\
    "\tcompanion object {\n".freeze

    KOTLIN_BUNDLE_HEADER = 
    "package com.hole19golf.hole19.analytics\n"\
    "import com.hole19golf.hole19.analytics.Event\n\n"\
    "enum class MixpanelEvent(override val key: String) : Event {\n".freeze

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
        properties += kotlin_people_const(prop)
      end
      properties += "\t}\n }"
    end

    def event_enum(bundle)
      event_file = KOTLIN_BUNDLE_HEADER
      bundle.each do |event|
        event_file += kotlin_event_const(event)
      end
      event_file += "\n}"
    end

    def kotlin_function(event_data)
      if !event_data.properties.nil?
        props = json_props(event_data.properties)
        function_body =
        "\nopen fun #{event_data.function_name}(#{event_data.properties}) {"\
        "#{props}"\
        "\tmixpanelMask.trackEvent(MixpanelEvent.#{event_data.event_name.upcase}, properties)\n"
      else
        props = nil
        function_body =
        "\nopen fun #{event_data.function_name}(#{event_data.properties}) {\n"\
        "\tmixpanelMask.trackEvent(MixpanelEvent.#{event_data.event_name.upcase})\n"    
      end
      function_body += "}\n"
    end

    def kotlin_people_const(prop)
      people_property = "\t\tconst val #{prop.property_name} = '#{prop.property_value}'\n"
    end

    def kotlin_event_const(event)
      kotlin_event = "\t\t #{event.event_name.upcase}(" + %Q{"#{event.event_name}"} + "),\n"
    end

    def kotlin_enum(enum)
      enum_body = "package com.hole19golf.hole19.analytics\n\n"
      enum_values = enum.values.split(',')
      enum_body += "enum class #{enum.enum_name}(val key: String) {\n"
      enum_values.each do |vals|
        enum_body += "\t#{vals.tr(" ","_").upcase}(" + %Q{"#{vals}"} + "),\n"
      end
      enum_body += "} \n"
    end


    def json_props(properties)
      split_properties = ""
      properties.split(',').each do |prop|
        if is_special_property(prop)
          split_properties += "\t\tput(" + %Q{"#{prop.split(":").first()}"} + ", " + prop.split(":").first() + ")\n"
        else
          split_properties += "\t\tput(" + %Q{"#{prop.split(":").first()}"} + ", " + prop.split(":").first() + ".key)\n"
        end
      end
      resulting_json = "\n\tval properties = JSONObject().apply {\n" +
      +"#{split_properties}"
      resulting_json += "\n\t}\n"
    end

    def is_special_property(prop)
      types_array = ['Long', 'Int','String', 'Double', 'Float', 'Boolean']
      type = prop.split(':')[1]
      types_array.include?(type) ? true : false
    end
  end
end