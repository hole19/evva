require 'net/https'
require 'csv'

module Evva
  class GoogleSheet
    def initialize(events_url, people_properties_url, enum_classes_url)
      @events_url = events_url
      @people_properties_url = people_properties_url
      @enum_classes_url = enum_classes_url
    end

    def events
      Logger.info("Downloading data from Google Sheet at #{@events_url}")
      csv = get_csv(@events_url)

      event_list = []
      csv.each do |row|
        event_name = row['Event Name']
        properties = hash_parser(row['Event Properties'])
        event_list << Evva::MixpanelEvent.new(event_name, properties)
      end
      event_list
    end

    def people_properties
      Logger.info("Downloading data from Google Sheet at #{@people_properties_url}")
      csv = get_csv(@people_properties_url)

      people_list = []
      csv.each do |row|
        value = row['Property Name']
        people_list << value
      end
      people_list
    end

    def enum_classes
      Logger.info("Downloading data from Google Sheet at #{@enum_classes_url}")
      csv = get_csv(@enum_classes_url)

      enum_list = []
      csv.each do |row|
        enum_name = row['Enum Name']
        values = row['Possible Values'].split(',')
        enum_list << Evva::MixpanelEnum.new(enum_name, values)
      end
      enum_list
    end

    private

    def get_csv(url)
      data = get(url)

      begin
        CSV.parse(data, headers: true)
      rescue StandardError => e
        raise "Cannot parse. Expected CSV at #{url}: #{e}"
      end
    end

    def get(url, max_redirects = 1)
      raise "Too may redirects" if max_redirects == -1

      uri = URI(url)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)

      return get(response['location'], max_redirects - 1) if response.is_a? Net::HTTPRedirection

      raise "Http Error #{response.body}" if response.code.to_i >= 400

      response.body
    end

    def hash_parser(property_array)
      h = {}
      unless property_array.nil? || property_array.empty?
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
