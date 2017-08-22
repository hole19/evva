require 'fileutils'

module Evva
  class EventGenerator
    def build(data, type, path)
      if type.eql? "Android"
        if file = open_file("#{path}/mixpanel.kt", "w", false)
          file.write(generate_kotlin_header)
          data.each do |event|
            file.write(generate_kotlin_function(event))
          end
          file.write("\n}")
        end
      end
      
      if type.eql? 'iOS'
        if file = open_file("#{path}/mixpanel.swift", "w", false)
          data.each do |event|
            file.write(generate_swift_function(event))
          end
        end
      end

        file.flush
        file.close
  end

    def generate_kotlin_function(eventData)
      if !eventData.properties.nil?
        props = generate_json_props(eventData.properties)
        functionBody = 
      "\nfun #{eventData.functionName}(#{eventData.properties}) {"\
          "#{props}"\
      "\tmixpanelApi.trackEvent('#{eventData.eventName}', properties)\n"
      else
        props = nil
        functionBody = 
      "\nfun #{eventData.functionName}(#{eventData.properties}) {\n"\
          "\tmixpanelApi.trackEvent('#{eventData.eventName}')\n"    
      end
      functionBody += "}\n"
    end

    def generate_swift_function(eventData)
      functionBody = "case .#{eventData.functionName}(): \n" + 
       "return EventData(name:" + "'#{eventData.eventName}'" + ", properties: [#{eventData.properties}]\n"
      functionBody
    end

    def generate_json_props(properties)
      splitProperties = ""
      properties.split(',').each do |prop|
        if is_special_property(prop)
          splitProperties += "\t\tput('" + "#{prop.split(":").first()}', " + prop.split(":").first() + ")\n"
        else
          splitProperties += "\t\tput('" + "#{prop.split(":").first()}', " + prop.split(":").first() + ".key)\n"
        end
      end
      resultingJson = "\n\tval properties = JSONObject().apply {\n" +
        +"#{splitProperties}"
      resultingJson += "\n\t}\n"
    end

    def generate_kotlin_header
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