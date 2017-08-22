require 'net/https'
require 'xmlsimple'

module Evva
  class GoogleSheet
    def initialize(sheet_id, keys_column)
      @sheet_id = sheet_id
      @key_column = keys_column
    end

    def generate_events
      raw = raw_data(@sheet_id, 0)
      Logger.info('Downloading dictionary from Google Sheet...')
      non_language_columns = ["id", "updated", "category", "title", "content", "link"]
      eventList = []
      raw["entry"].each do |entry|
        filteredEntry = entry.select { |c| !non_language_columns.include?(c) } 
        function = filteredEntry["functionname"].first
        eventName = filteredEntry["eventname"].first
        properties = filteredEntry["props"].first
        eventList.push(Evva::MixpanelEvent.new(function, eventName, properties))
      end
      eventList
    end

    def generate_people_properties
      raw = raw_data(@sheet_id, 1)
      Logger.info('Downloading dictionary from Google Sheet...')
      non_language_columns = ["id", "updated", "category", "title", "content", "link"]
      raw["entry"].each do |entry|
        filteredEntry = entry.select { |c| !non_language_columns.include?(c) } 
        puts filteredEntry
      end
    end

    def generate_enum_classes
      raw = raw_data(@sheet_id, 2)
      Logger.info('Downloading dictionary from Google Sheet...')
      non_language_columns = ["id", "updated", "category", "title", "content", "link"]
      enumList = []
      raw["entry"].each do |entry|
        filteredEntry = entry.select { |c| !non_language_columns.include?(c) } 
        enumName = filteredEntry["enum"].first
        values = filteredEntry["values"].first
        enumList.push(Evva::MixpanelEnum.new(enumName, values))
      end
      enumList
    end

    def xml_data(uri, headers = nil)
      uri = URI.parse(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      data = http.get(uri.path, headers)
      unless data.code.to_i == 200
        raise 'Cannot access sheet at #{uri} - HTTP #{data.code}'
      end

      begin
        XmlSimple.xml_in(data.body, 'KeyAttr' => 'name')
      rescue
        raise 'Cannot parse. Expected XML at #{uri}'
      end
    end

    def raw_data(sheet_id, sheetNumber)
      Logger.info('Downloading Google Sheet...')
      sheet = xml_data("https://spreadsheets.google.com/feeds/worksheets/#{sheet_id}/public/full")
      url   = sheet["entry"][sheetNumber]["link"][0]["href"]
      xml_data(url)
    end
  end
end