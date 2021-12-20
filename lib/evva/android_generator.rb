module Evva
  class AndroidGenerator
    attr_accessor :package_name

    def initialize(package_name)
      @package_name = package_name
    end

    BASE_TEMPLATE = File.expand_path("./templates/kotlin/base.kt", __dir__)
    EVENTS_TEMPLATE = File.expand_path("./templates/kotlin/events.kt", __dir__)
    EVENT_ENUM_TEMPLATE = File.expand_path("./templates/kotlin/event_enum.kt", __dir__)
    PEOPLE_PROPERTIES_TEMPLATE = File.expand_path("./templates/kotlin/people_properties.kt", __dir__)
    PEOPLE_PROPERTIES_ENUM_TEMPLATE = File.expand_path("./templates/kotlin/people_properties_enum.kt", __dir__)
    SPECIAL_PROPERTY_ENUMS_TEMPLATE = File.expand_path("./templates/kotlin/special_property_enums.kt", __dir__)
    PLATFORMS_TEMPLATE = File.expand_path("./templates/kotlin/platforms.kt", __dir__)

    TAB_SIZE = "    " # \t -> 4 spaces

    NATIVE_TYPES = %w[Long Int String Double Float Boolean].freeze

    def events(bundle, file_name, enums_file_name, platforms_file_name)
      header_footer_wrapper do
        class_name = file_name
        enums_class_name = enums_file_name
        platforms_class_name = platforms_file_name

        events = bundle.map do |event|
          properties = event.properties.map do |name, type|
            param_name = camelize(name.to_s, false)
            value_fetcher = param_name

            if !NATIVE_TYPES.include?(type.chomp('?'))
              # special property, we'll use rawValue
              if type.end_with?('?')
                # optional value, we need ? to access a parameter
                value_fetcher += "?"
              end
              value_fetcher += ".key"
            end

            {
              param_name: param_name,
              value_fetcher: value_fetcher,
              type: type,
              name: name.to_s,
            }
          end

          platforms = event.platforms.map { |p| constantize(p) }

          {
            class_name: camelize(event.event_name),
            event_name: constantize(event.event_name),
            properties: properties,
            platforms: platforms,
            is_object: properties.count == 0 && platforms.count == 0,
          }
        end

        template_from(EVENTS_TEMPLATE).result(binding)
      end
    end

    def event_enum(bundle, file_name)
      header_footer_wrapper do
        class_name = file_name

        events = bundle.map(&:event_name).map do |event_name|
          {
            name: constantize(event_name),
            value: event_name,
          }
        end

        template_from(EVENT_ENUM_TEMPLATE).result(binding)
      end
    end

    def people_properties(people_bundle, file_name, enums_file_name, platforms_file_name)
      header_footer_wrapper do
        class_name = file_name
        enums_class_name = enums_file_name
        platforms_class_name = platforms_file_name

        properties = people_bundle.map do |property|
          {
            class_name: camelize(property.property_name),
            property_name: constantize(property.property_name),
            type: property.type,
            platforms: property.platforms.map { |p| constantize(p) },
          }
        end

        template_from(PEOPLE_PROPERTIES_TEMPLATE).result(binding)
      end
    end

    def people_properties_enum(people_bundle, file_name)
      header_footer_wrapper do
        class_name = file_name

        properties = people_bundle.map(&:property_name).map do |property_name|
          {
            name: constantize(property_name),
            value: property_name,
          }
        end

        template_from(PEOPLE_PROPERTIES_ENUM_TEMPLATE).result(binding)
      end
    end

    def special_property_enums(enums_bundle)
      header_footer_wrapper do
        enums = enums_bundle.map do |enum|
          values = enum.values.map do |value|
            {
              name: constantize(value),
              value: value,
            }
          end

          {
            class_name: enum.enum_name,
            values: values,
          }
        end

        template_from(SPECIAL_PROPERTY_ENUMS_TEMPLATE).result(binding)
      end
    end

    def platforms(bundle, file_name)
      header_footer_wrapper do
        class_name = file_name

        platforms = bundle.map { |platform| constantize(platform) }

        template_from(PLATFORMS_TEMPLATE).result(binding)
      end
    end

    private

    def header_footer_wrapper
      package_name = @package_name

      content = yield
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

    # extracted from Rails' ActiveSupport
    def camelize(string, uppercase_first_letter = true)
      string = string.to_s
      if uppercase_first_letter
        string = string.sub(/^[a-z\d]*/) { |match| match.capitalize }
      else
        string = string.sub(/^(?:(?=\b|[A-Z_])|\w)/) { |match| match.downcase }
      end
      string.gsub(/(?:_|(\/))([a-z\d]*)/) { "#{$1}#{$2.capitalize}" }.gsub("/", "::")
    end

    def constantize(string)
      string.tr(' ', '_').upcase
    end
  end
end
