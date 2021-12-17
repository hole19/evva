sealed class <%= class_name %>(event: <%= enums_class_name %>) {
    val name = event.key

    open val properties: Map<String, Any?>? = null

    <%- events.each_with_index do |e, index| -%>
    <%- if e[:properties].count == 0 -%>
    object <%= e[:class_name] %> : <%= class_name %>(<%= enums_class_name %>.<%= e[:event_name] %>)
    <%- else -%>
    data class <%= e[:class_name] %>(
        <%= e[:properties].map { |p| "val #{p[:param_name]}: #{p[:type]}" }.join(", ") %>
    ) : <%= class_name %>(<%= enums_class_name %>.<%= e[:event_name] %>) {
        override val properties = mapOf(
            <%- e[:properties].each_with_index do |p, index| -%>
            "<%= p[:name] %>" to <%= p[:value_fetcher] %><% if index < e[:properties].count - 1 %>,<% end %>
            <%- end -%>
        )
    }
    <%- end -%>
    <%- unless index == events.count - 1 -%>

    <%- end -%>
    <%- end -%>
}
