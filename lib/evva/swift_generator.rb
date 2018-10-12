module Evva
  class SwiftGenerator
    EXTENSION_HEADER =
      "\nimport Foundation\n\n"\
      "extension Analytics {\n\n".freeze

    EXTENSION_FOOTER =
      "\n\n}\n"

    NATIVE_TYPES = %w[Int String Double Float Bool].freeze

    def events(bundle, file_name)
      header_footer_wrapper do
"""\tenum Event {
#{bundle.map { |e| event_case(e) }.join("\n")}

\t\tvar data: EventData {
\t\t\tswitch self {
#{bundle.map { |e| event_data(e) }.join("\n\n")}
\t\t\t}
\t\t}
\t}"""
      end
    end

    def event_case(event_data)
      function_name = camelize(event_data.event_name)
      if event_data.properties.empty?
        "\t\tcase #{function_name}"
      else
        trimmed_properties = event_data.properties.map { |k, v| k.to_s + ': ' + native_type(v) }.join(", ")
        "\t\tcase #{function_name}(#{trimmed_properties})"
      end
    end

    def event_data(event_data)
      function_name = camelize(event_data.event_name)
      if event_data.properties.empty?
        function_body = "\t\t\tcase .#{function_name}:\n" \
                        "\t\t\t\treturn EventData(name: \"#{event_data.event_name}\")"
      else
        function_header = prepend_let(event_data.properties)
        function_arguments = dictionary_pairs(event_data.properties)
        function_body = "\t\t\tcase .#{function_name}(#{function_header}):\n"\
                        "\t\t\t\treturn EventData(name: \"#{event_data.event_name}\", properties: [\n"\
                        "\t\t\t\t\t#{function_arguments.join(",\n\t\t\t\t\t")} ]\n"\
                        "\t\t\t\t)"
      end
      function_body
    end

    def event_enum(enum, file_name)
      # empty
    end

    def people_properties(people_bundle, file_name)
      header_footer_wrapper do
        props = "\tenum Property: String {\n"
        people_bundle.each do |prop|
          props << "\t\tcase #{camelize(prop)} = \"#{prop}\"\n"
        end
        props << "\t}"
      end
    end

    def special_property_enums(enums)
      header_footer_wrapper do
        enums.map do |enum|
          body = "\tenum #{enum.enum_name}: String {\n"
          enum.values.each do |value|
            body << "\t\tcase #{camelize(value)} = \"#{value}\"\n"
          end
          body << "\t}"
        end.join("\n\n")
      end
    end

    private

    def header_footer_wrapper
"""import Foundation

extension Analytics {

#{yield.gsub("\t", "    ")}
}
"""
    end

    def dictionary_pairs(props)
      props.map do |name, type|
        pair = "\"#{name}\": #{name}"
        if is_raw_representable_property?(type)
          if is_optional_property?(type)
            pair += "?"
          end
          pair += ".rawValue"
        end
        pair += " as Any"
      end
    end

    def is_raw_representable_property?(type)
      !NATIVE_TYPES.include?(native_type(type).chomp('?'))
    end

    def is_optional_property?(type)
      type.end_with?('?')
    end

    def native_type(type)
      type.gsub('Boolean','Bool').gsub('Long', 'Int')
    end

    def prepend_let(props)
      props.map { |k, v| "let #{k}" }.join(', ')
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
