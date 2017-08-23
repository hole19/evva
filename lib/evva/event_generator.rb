require 'fileutils'

module Evva
  class EventGenerator
    def build(data, type, path)
      if type.eql? "Android"
        if file = open_file("#{path}/mixpanel.kt", "w", false)
          file.write(kotlin_header)
          data.each do |event|
            file.write(kotlin_function(event))
          end
          file.write("\n}")
        end
      end
      
      if type.eql? 'iOS'
        if file = open_file("#{path}/mixpanel.swift", "w", false)
          data.each do |event|
            file.write(swift_function(event))
          end
        end
      end

      file.flush
      file.close
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

    def swift_function(event_data)
      function_body = "case .#{event_data.function_name}(): \n" + 
      "return EventData(name:" + "'#{event_data.event_name}'" + ", properties: [#{event_data.properties}]\n"
      function_body
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

    def kotlin_header
      header = 
      "package com.hole19golf.hole19.analytics\n"\
      "import com.hole19golf.hole19.analytics.Event\n\n"\
      "class MixpanelAnalytics(val mixpanelAPI: MixpanelAPI) {\n"
    end

    def is_special_property(prop)
      types_array = ['Long', 'Integer','String', 'Double', 'Float']
      type = prop.split(':')[1]
      types_array.include?(type) ? true : false
    end

    def open_file(file_name, method, should_exist)
      if !File.file?(File.expand_path(file_name))
        if should_exist
          Logger.error("File #{file_name} not found!")
          return nil
        else
          FileUtils.mkdir_p(File.dirname(file_name))
        end
      end

      File.open(File.expand_path(file_name), method)
    end
  end
end