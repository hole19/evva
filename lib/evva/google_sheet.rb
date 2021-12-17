require 'net/https'
require 'csv'

module Evva
  class GoogleSheet
    EVENT_NAME = 'Event Name'
    EVENT_PROPERTIES = 'Event Properties'
    EVENT_PLATFORMS = 'Event Destination'

    PROPERTY_NAME = 'Property Name'
    PROPERTY_TYPE = 'Property Type'
    PROPERTY_PLATFORMS = 'Property Destination'

    ENUM_NAME = 'Enum Name'
    ENUM_VALUES = 'Possible Values'

    def initialize(events_url, people_properties_url, enum_classes_url)
      @events_url = events_url
      @people_properties_url = people_properties_url
      @enum_classes_url = enum_classes_url
    end

    def events
      @events_csv ||= begin
        Logger.info("Downloading data from Google Sheet at #{@events_url}")
        get_csv(@events_url)
      end

      @events_csv.map do |row|
        event_name = row[EVENT_NAME]
        properties = hash_parser(row[EVENT_PROPERTIES])
        platforms = row[EVENT_PLATFORMS]&.split(',')
        Evva::AnalyticsEvent.new(event_name, properties, platforms || [])
      end
    end

    def people_properties
      @people_properties_csv ||= begin
        Logger.info("Downloading data from Google Sheet at #{@people_properties_url}")
        get_csv(@people_properties_url)
      end

      @people_properties_csv.map do |row|
        property_name = row[PROPERTY_NAME]
        property_type = row[PROPERTY_TYPE]
        platforms = row[PROPERTY_PLATFORMS]&.split(',')
        Evva::AnalyticsProperty.new(property_name, property_type, platforms || [])
      end
    end

    def enum_classes
      @enum_classes_csv ||= begin
        Logger.info("Downloading data from Google Sheet at #{@enum_classes_url}")
        get_csv(@enum_classes_url)
      end

      @enum_classes_csv.map do |row|
        enum_name = row[ENUM_NAME]
        values = row[ENUM_VALUES].split(',')
        Evva::AnalyticsEnum.new(enum_name, values)
      end
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
