require 'net/https'
require 'xmlsimple'

module Evva
  class GoogleSheet
    def initialize(sheet_id)
      @sheet_id = sheet_id
    end

    def events
      event_list = []
      iterate_entries(raw_data(@sheet_id, 0)) do |entry|
        event_name = entry['eventname'].first
        properties = hash_parser(entry['props'].first)
        event_list << Evva::MixpanelEvent.new(event_name, properties)
      end
      event_list
    end

    def people_properties
      people_list = []
      iterate_entries(raw_data(@sheet_id, 1)) do |entry|
        value = entry['value'].first
        people_list << value
      end
      people_list
    end

    def enum_classes
      enum_list = []
      iterate_entries(raw_data(@sheet_id, 2)) do |entry|
        enum_name = entry['enum'].first
        values = entry['values'].first.split(',')
        enum_list << Evva::MixpanelEnum.new(enum_name, values)
      end
      enum_list
    end

    private

    def iterate_entries(data)
      Logger.info('Downloading dictionary from Google Sheet...')
      non_language_columns = %w[id updated category title content link]
      data['entry'].each do |entry|
        filtered_entry = entry.reject { |c| non_language_columns.include?(c) }
        yield(filtered_entry)
      end
    end

    def xml_data(uri, headers = nil)
      uri = URI.parse(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      data = http.get(uri.path, headers)
      unless data.code.to_i == 200
        raise "Cannot access sheet at #{uri} - HTTP #{data.code}"
      end

      begin
        XmlSimple.xml_in(data.body, 'KeyAttr' => 'name')
      rescue
        raise "Cannot parse. Expected XML at #{uri}"
      end
    end

    def raw_data(sheet_id, sheet_number)
      Logger.info('Downloading Google Sheet...')
      sheet = xml_data("https://spreadsheets.google.com/feeds/worksheets/#{sheet_id}/public/full")
      url   = sheet['entry'][sheet_number]['link'][0]['href']
      xml_data(url)
    end

    def hash_parser(property_array)
      h = {}
      unless property_array.empty?
        property_array.split(',').each do |prop|
          split_prop = prop.split(':')
          prop_name = split_prop[0].to_sym
          prop_type = split_prop[1].to_s
          h[prop_name] = prop_type
        end
      end
      h
    end
  end
end
