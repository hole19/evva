sealed class <%= class_name %>(
    event: <%= enums_class_name %>,
    val properties: Map<String, Any?>? = null,
    val destinations: Array<<%= destinations_class_name %>> = emptyArray()
) {
    val name = event.key

    <%- events.each_with_index do |e, index| -%>
    <%- if e[:properties].count == 0 -%>
    data object <%= e[:class_name] %> : <%= class_name %>(
    <%- else -%>
    data class <%= e[:class_name] %>(
        <%- e[:properties].each_with_index do |p, index| -%>
        <%= "val #{p[:param_name]}: #{p[:type]}" %><% if index < e[:properties].count - 1 %>,<% end %>
        <%- end -%>
    ) : <%= class_name %>(
    <%- end -%>
        event = <%= enums_class_name %>.<%= e[:event_name] %>,
        <%- if e[:properties].count > 0 -%>
        properties = mapOf(
            <%- e[:properties].each_with_index do |p, index| -%>
            "<%= p[:name] %>" to <%= p[:value_fetcher] %><% if index < e[:properties].count - 1 %>,<% end %>
            <%- end -%>
        ),
        <%- end -%>
        <%- if e[:destinations].count > 0 -%>
        destinations = arrayOf(
            <%- e[:destinations].each_with_index do |d, index| -%>
            <%= destinations_class_name %>.<%= d %><% if index < e[:destinations].count - 1 %>,<% end %>
            <%- end -%>
        )
        <%- end -%>
    )
    <%- unless index == events.count - 1 -%>

    <%- end -%>
    <%- end -%>
}
