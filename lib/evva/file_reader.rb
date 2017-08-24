require 'fileutils'

module Evva
  class FileReader

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