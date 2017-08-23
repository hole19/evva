require 'fileutils'

module Evva
  class EnumGenerator
    def build(data, type, path)
      if type.eql? "Android"
        data.each do |enum|
          file = open_file("#{path}/#{enum.enum_name}.kt", "w", false)
          file.write(kotlin_enum(enum))
          file.flush
          file.close
        end
      end

      if type.eql? 'iOS'
        data.each do |enum|
          file = open_file("./#{enum.enum_name}.swift", "w", false)
          file.write(generate_swift_enum(enum))
          file.flush
          file.close
        end
      end
    end

    def kotlin_enum(enum)
      enum_values = enum.values.split(',')
      enum_body = "enum class #{enum.enum_name}(val key: String) {\n"
      enum_values.each do |vals|
        enum_body += "\t#{vals.upcase}(" + "'#{vals}'" + "),\n"
      end
      enum_body += "} \n"
    end

    def generate_swift_enum(enum)
      enum_values = enum.values.split(',')
      enum_body = "enum #{enum.enum_name}: String {\n"
      enum_values.each do |vals|
        enum_body += "\tcase #{vals} = "+ "'#{vals}'" + "\n"
      end
      enum_body += "} \n"
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