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

    def swift_function(event_data)
      function_body = "case .#{event_data.function_name}(): \n" + 
      "return EventData(name:" + "'#{event_data.event_name}'" + ", properties: [#{event_data.properties}]\n"
      function_body
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