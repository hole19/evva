module Evva
  class AndroidGenerator
    attr_accessor :package_name

    def initialize(package_name)
      @package_name = package_name
    end

    NATIVE_TYPES = %w[Long Int String Double Float Boolean].freeze

    def events(bundle, file_name)
      header_footer_wrapper do
"""sealed class #{file_name}(event: AnalyticsEvents) {
\tval name = event.key

\topen val properties: Map<String, Any?>? = null

#{bundle.map { |e| event_class(e, file_name) }.join("\n\n")}
}"""
      end
    end

    def people_properties(people_bundle, file_name)
      header_footer_wrapper do
        body = "enum class #{file_name}(val key: String) {\n"
        body << people_bundle.map { |prop| "\t#{prop.upcase}(\"#{prop}\")" }.join(",\n")
        body << ";\n}"
      end
    end

    def event_enum(bundle, file_name)
      header_footer_wrapper do
        body = "enum class #{file_name}(val key: String) {\n"
        body << bundle.map(&:event_name).map { |prop| "\t#{prop.upcase}(\"#{prop}\")" }.join(",\n")
        body << ";\n}"
      end
    end

    def special_property_enums(enums)
      header_footer_wrapper do
        enums.map do |enum|
          body = "enum class #{enum.enum_name}(val key: String) {\n"
          body << enum.values.map { |vals| "\t#{vals.tr(' ', '_').upcase}(\"#{vals}\")"}.join(",\n")
          body << ";\n}"
        end.join("\n\n")
      end
    end

    private

    def imports_header(imports = [])
      return unless imports.length > 0
      imports.map { |ev| ev. gsub("packagename", @package_name) }
             .join("\n") + "\n\n"
    end

    def header_footer_wrapper(imports = [])
<<-Kotlin
package #{@package_name}

#{imports_header(imports)}/**
 * This file was automatically generated by evva: https://github.com/hole19/evva
 */

#{yield.gsub("\t", "    ")}
Kotlin
    end

    def event_class(event_data, superclass_name)
      class_name = camelize(event_data.event_name)
      class_arguments = event_data.properties.map { |name, type| "val #{camelize(name, false)}: #{type}" }.join(', ')
      if !class_arguments.empty?
        props = props_map(event_data.properties)

"""\tdata class #{class_name}(
\t\t#{class_arguments}
\t) : #{superclass_name}(AnalyticsEvents.#{event_data.event_name.upcase}) {
#{props}
\t}"""

      else
"""\tdata class #{class_name} : #{superclass_name}(AnalyticsEvents.#{event_data.event_name.upcase})"""
      end
    end

    def props_map(properties)
      split_properties =
        properties
        .map.with_index do |data, index|
          name, type = data
          prop = "\t\t\t\"#{name}\" to #{camelize(name, false)}"

          if special_property?(type)
            if optional_property?(type)
              prop = "#{prop}?"
            end
            prop = "#{prop}.key"
          end

          if index < properties.size - 1
            # add list comma to every property except the last one
            prop = "#{prop},"
          end

          prop
        end
        .join("\n")

      "\t\toverride val properties = mapOf(\n#{split_properties}\n\t\t)"
    end

    def special_property?(type)
      !NATIVE_TYPES.include?(type.chomp('?'))
    end

    def optional_property?(type)
      type.include?('?')
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
  end
end
