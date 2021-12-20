require 'erb'

module Evva
  class SwiftGenerator
    BASE_TEMPLATE = File.expand_path("./templates/swift/base.swift", __dir__)
    EVENTS_TEMPLATE = File.expand_path("./templates/swift/events.swift", __dir__)
    PEOPLE_PROPERTIES_TEMPLATE = File.expand_path("./templates/swift/people_properties.swift", __dir__)
    SPECIAL_PROPERTY_ENUMS_TEMPLATE = File.expand_path("./templates/swift/special_property_enums.swift", __dir__)
    PLATFORMS_TEMPLATE = File.expand_path("./templates/swift/platforms.swift", __dir__)

    TAB_SIZE = "    " # \t -> 4 spaces

    NATIVE_TYPES = %w[Int String Double Float Bool].freeze

    def events(bundle, _file_name, _enums_file_name, _platforms_file_name)
      header_footer_wrapper do
        events = bundle.map do |event|
          properties = event.properties.map { |k, v|
            type = native_type(v)

            value_fetcher = k.to_s

            if !NATIVE_TYPES.include?(type.chomp('?'))
              # special property, we'll use rawValue
              if type.end_with?('?')
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
            platforms: event.platforms.map { |p| camelize(p) },
          }
        end

        template_from(EVENTS_TEMPLATE).result(binding)
      end
    end

    def event_enum(_enum_bundle, _file_name)
      # empty
    end

    def people_properties(people_bundle, _file_name)
      header_footer_wrapper do
        properties = people_bundle.map do |p|
          {
            case_name: camelize(p.property_name),
            property_name: p.property_name,
            type: native_type(p.type),
            platforms: p.platforms.map { |p| camelize(p) },
          }
        end

        template_from(PEOPLE_PROPERTIES_TEMPLATE).result(binding)
      end
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

    def platforms(platforms_bundle, _file_name)
      header_footer_wrapper do
        platforms = platforms_bundle.map { |p| camelize(p) }

        template_from(PLATFORMS_TEMPLATE).result(binding)
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

      # - 2nd argument (nil) changes nothing
      # - 3rd argument activates trim mode using "-" so that you can decide to
      # not include a line (useful on loops and if statements)
      ERB.new(file, nil, '-')
    end

    def native_type(type)
      type
        .gsub('Boolean','Bool')
        .gsub('Long', 'Int')
    end

    def camelize(term)
      string = term.to_s.tr(' ', '_').downcase
      string = string.sub(/^(?:#{@acronym_regex}(?=\b|[A-Z_])|\w)/) { |match| match.downcase }
      string.gsub!(/(?:_|(\/))([a-z\d]*)/i) { "#{$1}#{$2.capitalize}" }
      string.gsub!("/".freeze, "::".freeze)
      string
    end
  end
end
