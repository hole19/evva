require "erb"

module Evva
  class SwiftGenerator
    BASE_TEMPLATE = File.expand_path("./templates/swift/base.swift", __dir__)
    EVENTS_TEMPLATE = File.expand_path("./templates/swift/events.swift", __dir__)
    PEOPLE_PROPERTIES_TEMPLATE = File.expand_path("./templates/swift/people_properties.swift", __dir__)
    SPECIAL_PROPERTY_ENUMS_TEMPLATE = File.expand_path("./templates/swift/special_property_enums.swift", __dir__)
    DESTINATIONS_TEMPLATE = File.expand_path("./templates/swift/destinations.swift", __dir__)

    TAB_SIZE = "    " # \t -> 4 spaces

    NATIVE_TYPES = %w[Int String Double Float Bool Date].freeze

    def events(bundle, _file_name, _enums_file_name, _destinations_file_name)
      header_footer_wrapper do
        events = bundle.map do |event|
          properties = event.properties.map { |k, v|
            type = native_type(v)

            value_fetcher = k.to_s

            if is_special_property?(type)
              if type.end_with?("?")
                # optional value, we need ? to access a parameter
                value_fetcher += "?"
              end
              value_fetcher += ".rawValue"
            end

            {
              name: k.to_s,
              type: type,
              value: value_fetcher,
            }
          }

          {
            case_name: camelize(event.event_name),
            event_name: event.event_name,
            properties: properties,
            destinations: event.destinations.map { |p| camelize(p) },
          }
        end

        template_from(EVENTS_TEMPLATE).result(binding)
      end
    end

    def event_enum
      # empty
    end

    def people_properties(people_bundle, _file_name, _enums_file_name, _destinations_file_name)
      header_footer_wrapper do
        properties = people_bundle.map do |p|
          type = native_type(p.type)
          {
            case_name: camelize(p.property_name),
            property_name: p.property_name,
            type: type,
            is_special_property: is_special_property?(type),
            destinations: p.destinations.map { |p| camelize(p) },
          }
        end

        template_from(PEOPLE_PROPERTIES_TEMPLATE).result(binding)
      end
    end

    def people_properties_enum
      # empty
    end

    def special_property_enums(enums_bundle)
      header_footer_wrapper do
        enums = enums_bundle.map do |enum|
          values = enum.values.map do |value|
            {
              case_name: camelize(value),
              value: value
            }
          end

          {
            name: enum.enum_name,
            values: values
          }
        end

        template_from(SPECIAL_PROPERTY_ENUMS_TEMPLATE).result(binding)
      end
    end

    def destinations(destinations_bundle, _file_name)
      header_footer_wrapper do
        destinations = destinations_bundle.map { |p| camelize(p) }

        template_from(DESTINATIONS_TEMPLATE).result(binding)
      end
    end

  private

    def header_footer_wrapper
      content = yield
        .gsub(/^/, "\t").gsub(/^\t+$/, "") # add tabs, unless it's an empty line
        .chop # trim trailing newlines created by sublime

      template_from(BASE_TEMPLATE).result(binding).gsub("\t", TAB_SIZE)
    end

    def template_from(path)
      file = File.read(path)

      # trim mode using "-" so that you can decide to not include a line (useful on loops and if statements)
      ERB.new(file, trim_mode: "-")
    end

    def native_type(type)
      type
        .gsub("Boolean","Bool")
        .gsub("Long", "Int")
    end

    def is_special_property?(type)
      !NATIVE_TYPES.include?(type.chomp("?"))
    end

    def camelize(term)
      string = term.to_s.tr(" ", "_").downcase
      string = string.sub(/^(?:#{@acronym_regex}(?=\b|[A-Z_])|\w)/) { |match| match.downcase }
      string.gsub!(/(?:_|(\/))([a-z\d]*)/i) { "#{$1}#{$2.capitalize}" }
      string.gsub!("/".freeze, "::".freeze)
      string
    end
  end
end
