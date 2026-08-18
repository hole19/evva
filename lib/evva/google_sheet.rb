require "net/https"
require "csv"

require "evva/analytics_event"

module Evva
  class GoogleSheet
    EVENT_NAME = "Event Name"
    EVENT_PROPERTIES = "Event Properties"
    EVENT_DESTINATION = "Event Destination"
    EVENT_PLATFORM = "Platform"

    PROPERTY_NAME = "Property Name"
    PROPERTY_TYPE = "Property Type"
    PROPERTY_DESTINATION = "Property Destination"

    ENUM_NAME = "Enum Name"
    ENUM_VALUES = "Possible Values"

    # What a human may write in the `Platform` cell, mapped to the platforms each
    # spelling expands to. The identity entries are derived so that a platform
    # added to PLATFORMS cannot be accepted as a config type but rejected in a
    # cell.
    PLATFORM_ALIASES = begin
      platforms = Evva::AnalyticsEvent::PLATFORMS
      identities = platforms.to_h { |platform| [platform, [platform].freeze] }
      identities.merge("both" => platforms, "all" => platforms).freeze
    end

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

      @events ||= begin
        platform_header = header_matching(@events_csv, EVENT_PLATFORM)
        Logger.info("No #{EVENT_PLATFORM} column in the events sheet, every event will be generated for every platform") if platform_header.nil?

        @events_csv.map do |row|
          event_name = row[EVENT_NAME]
          properties = hash_parser(row[EVENT_PROPERTIES])
          destinations = row[EVENT_DESTINATION]&.split(",")
          platforms = platform_parser(platform_header && row[platform_header], event_name)
          Evva::AnalyticsEvent.new(event_name, properties, destinations || [], platforms)
        end
      end
    end

    def people_properties
      @people_properties_csv ||= begin
        Logger.info("Downloading data from Google Sheet at #{@people_properties_url}")
        get_csv(@people_properties_url)
      end

      @people_properties ||= @people_properties_csv.map do |row|
        property_name = row[PROPERTY_NAME]
        property_type = row[PROPERTY_TYPE]
        destinations = row[PROPERTY_DESTINATION]&.split(",")
        Evva::AnalyticsProperty.new(property_name, property_type, destinations || [])
      end
    end

    def enum_classes
      @enum_classes_csv ||= begin
        Logger.info("Downloading data from Google Sheet at #{@enum_classes_url}")
        get_csv(@enum_classes_url)
      end

      @enum_classes ||= @enum_classes_csv.map do |row|
        enum_name = row[ENUM_NAME]
        values = row[ENUM_VALUES].split(",")
        Evva::AnalyticsEnum.new(enum_name, values)
      end
    end

    def destinations
      @destinations ||= events.map(&:destinations).flatten.uniq
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

      return get(response["location"], max_redirects - 1) if response.is_a? Net::HTTPRedirection

      raise "Http Error #{response.body}" if response.code.to_i >= 400

      response.body
    end

    # Matched ignoring case and surrounding whitespace, because a header of
    # "platform" or "Platform " means what it plainly means, and matching it
    # strictly would silently disable the filter for the whole sheet rather than
    # fail. Deliberately used for this column only: a mistyped `Platform` fails
    # silently, whereas a mistyped `Event Name` fails loudly and at once.
    def header_matching(csv, name)
      csv.headers.compact.find { |header| header.to_s.strip.casecmp?(name) }
    end

    # nil (no Platform column) or a cell holding no tokens both mean every
    # platform, so a blank cell can never drop an event.
    def platform_parser(platform_list, event_name)
      tokens = platform_list.to_s.split(",").map(&:strip).reject(&:empty?)
      return Evva::AnalyticsEvent::PLATFORMS if tokens.empty?

      expanded = tokens.flat_map do |token|
        # The message quotes the token as written, not as normalised, so it can be
        # searched for in the sheet.
        PLATFORM_ALIASES.fetch(token.downcase) do
          raise "Unknown platform '#{token}' for event '#{event_name}'. " \
                "Expected any of #{PLATFORM_ALIASES.keys.join(', ')}, or an empty cell for every platform."
        end
      end

      # Intersecting dedups and takes canonical order from PLATFORMS itself,
      # rather than relying on it happening to be alphabetical.
      Evva::AnalyticsEvent::PLATFORMS & expanded
    end

    def hash_parser(property_array)
      h = {}
      unless property_array.nil? || property_array.empty?
        property_array.split(",").each do |prop|
          split_prop = prop.split(":")
          prop_name = split_prop[0].strip.to_sym
          prop_type = split_prop[1].to_s.strip
          h[prop_name] = prop_type
        end
      end
      h
    end
  end
end
