sealed class <%= class_name %>(event: <%= enums_class_name %>) {
    val name = event.key

    open val properties: Map<String, Any?>? = null
    open val platforms: Array<<%= platforms_class_name %>> = []

    <%- events.each_with_index do |e, index| -%>
    <%- if e[:is_object] -%>
    object <%= e[:class_name] %> : <%= class_name %>(<%= enums_class_name %>.<%= e[:event_name] %>)
    <%- else -%>
    data class <%= e[:class_name] %><% if e[:properties].count > 0 %>(
        <%= e[:properties].map { |p| "val #{p[:param_name]}: #{p[:type]}" }.join(", ") %>
    )<% end %> : <%= class_name %>(<%= enums_class_name %>.<%= e[:event_name] %>) {
        <%- if e[:properties].count > 0 -%>
        override val properties = mapOf(
            <%- e[:properties].each_with_index do |p, index| -%>
            "<%= p[:name] %>" to <%= p[:value_fetcher] %><% if index < e[:properties].count - 1 %>,<% end %>
            <%- end -%>
        )
        <%- end -%>
        <%- if e[:platforms].count > 0 -%>
        override val platforms = [
            <%- e[:platforms].each_with_index do |p, index| -%>
            <%= platforms_class_name %>.<%= p %><% if index < e[:platforms].count - 1 %>,<% end %>
            <%- end -%>
        ]
        <%- end -%>
    }
    <%- end -%>
    <%- unless index == events.count - 1 -%>

    <%- end -%>
    <%- end -%>
}
