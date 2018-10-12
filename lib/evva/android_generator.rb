module Evva
  class AndroidGenerator

    def events(bundle, file_name)
      header_footer_wrapper([IMPORT_EVENT, IMPORT_MASK, IMPORT_JSON]) do
"""open class #{file_name}(private val mask: MixpanelAnalyticsMask) {

#{bundle.map { |e| kotlin_function(e) }.join("\n\n")}

\topen fun updateProperties(property: MixpanelProperties, value: Any) {
\t\tmask.updateProperties(property.key, value)
\t}

\topen fun incrementCounter(property: MixpanelProperties) {
\t\tmask.incrementCounter(property.key)
\t}
}"""
      end
    end

    def people_properties(people_bundle, file_name)
      header_footer_wrapper do
        body = "enum class MixpanelProperties(val key: String) {\n"
        body << people_bundle.map { |prop| "\t#{prop.upcase}(\"#{prop}\")" }.join(",\n")
        body << ";\n}"
      end
    end

    def event_enum(bundle, file_name)
      header_footer_wrapper([IMPORT_EVENT]) do
        body = "enum class #{file_name}(override val key: String) : Event {\n"
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

    IMPORT_EVENT = "import com.hole19golf.hole19.analytics.Event".freeze
    IMPORT_MASK = "import com.hole19golf.hole19.analytics.MixpanelAnalyticsMask".freeze
    IMPORT_JSON = "import org.json.JSONObject".freeze

    NATIVE_TYPES = %w[Long Int String Double Float Boolean].freeze

    private

    def imports_header(imports = [])
      return unless imports.length > 0
      imports.join("\n") + "\n\n"
    end

    def header_footer_wrapper(imports = [])
<<-Kotlin
package com.hole19golf.hole19.analytics

#{imports_header(imports)}#{yield.gsub("\t", "    ")}
Kotlin
    end

    def kotlin_function(event_data)
      function_name = 'track' + titleize(event_data.event_name)
      function_arguments = event_data.properties.map { |name, type| "#{name}: #{type}" }.join(', ')
      if !function_arguments.empty?
        props = json_props(event_data.properties)
"""\topen fun #{function_name}(#{function_arguments}) {
#{props}
\t\tmask.trackEvent(MixpanelEvent.#{event_data.event_name.upcase}, properties)
\t}"""

      else
"""\topen fun #{function_name}() {
\t\tmask.trackEvent(MixpanelEvent.#{event_data.event_name.upcase})
\t}"""
      end
    end

    def json_props(properties)
      split_properties =
        properties
        .map do |name, type|
          if special_property?(type)
            if optional_property?(type)
              "#{name}?.let { put(\"#{name}\", it.key) }"
            else
              "put(\"#{name}\", #{name}.key)"
            end
          else
            if optional_property?(type)
              "#{name}?.let { put(\"#{name}\", it) }"
            else
              "put(\"#{name}\", #{name})"
            end
          end
        end
        .map { |line| "\t\t\t#{line}" }
        .join("\n")

      "\t\tval properties = JSONObject().apply {\n#{split_properties}\n\t\t}"
    end

    def special_property?(type)
      !NATIVE_TYPES.include?(type.chomp('?'))
    end

    def optional_property?(type)
      type.include?('?')
    end

    def titleize(str)
      str.split('_').collect(&:capitalize).join
    end
  end
end
