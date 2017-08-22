require 'fileutils'

module Evva
  class EnumGenerator
    def build(data, type, path)
      if type.eql? "Android"
        data.each do |enum|
          file = open_file("#{path}/#{enum.enumName}.kt", "w", false)
          file.write(generate_kotlin_enum(enum))
          file.flush
          file.close
        end
      end

      if type.eql? 'iOS'
        data.each do |enum|
          file = open_file("./#{enum.enumName}.swift", "w", false)
          file.write(generate_swift_enum(enum))
          file.flush
          file.close
        end
      end
    end

    def generate_kotlin_enum(enum)
      enumValues = enum.values.split(',')
      enumBody = "enum class #{enum.enumName}(val key: String) {\n"
      enumValues.each do |vals|
        enumBody += "\t#{vals.upcase}(" + "'#{vals}'" + "),\n"
      end
      enumBody += "} \n"
    end

    def generate_swift_enum(enum)
      enumValues = enum.values.split(',')
      enumBody = "enum #{enum.enumName}: String {\n"
      enumValues.each do |vals|
        enumBody += "\tcase #{vals} = "+ "'#{vals}'" + "\n"
      end
      enumBody += "} \n"
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