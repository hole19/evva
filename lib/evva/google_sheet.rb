require 'net/https'
require 'xmlsimple'

module Evva
  class GoogleSheet
    def initialize(sheet_id)
      @sheet_id = sheet_id
    end

    def events
      raw = raw_data(@sheet_id, 0)
      Logger.info('Downloading dictionary from Google Sheet...')
      non_language_columns = %w[id updated category
                                title content link]
      event_list = []
      raw['entry'].each do |entry|
        filtered_entry = entry.reject { |c| non_language_columns.include?(c) }
        event_name = filtered_entry['eventname'].first
        properties = filtered_entry['props'].first
        event_list.push(Evva::MixpanelEvent.new(event_name, properties))
      end
      event_list
    end

    def people_properties
      raw = raw_data(@sheet_id, 1)
      people_list = []
      Logger.info('Downloading dictionary from Google Sheet...')
      non_language_columns = %w[id updated category title content link]
      raw['entry'].each do |entry|
        filtered_entry = entry.reject { |c| non_language_columns.include?(c) }
        value = filtered_entry['value'].first
        people_list << value
      end
      people_list
    end

    def enum_classes
      raw = raw_data(@sheet_id, 2)
      Logger.info('Downloading dictionary from Google Sheet...')
      non_language_columns = %w[id updated category title content link]
      enum_list = []
      raw['entry'].each do |entry|
        filtered_entry = entry.reject { |c| non_language_columns.include?(c) }
        enum_name = filtered_entry['enum'].first
        values = filtered_entry['values'].first
        enum_list.push(Evva::MixpanelEnum.new(enum_name, values))
      end
      enum_list
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

    def raw_data(sheet_id, sheet_number)
      Logger.info('Downloading Google Sheet...')
      sheet = xml_data("https://spreadsheets.google.com/feeds/worksheets/#{sheet_id}/public/full")
      url   = sheet['entry'][sheet_number]['link'][0]['href']
      xml_data(url)
    end
  end
end
