<%- enums.each_with_index do |enum, index| -%>
enum class <%= enum[:class_name] %>(val key: String) {
	<%- enum[:values].each_with_index do |v, index| -%>
	<%= v[:name] %>("<%= v[:value] %>")<%= index == enum[:values].count - 1 ? "" : "," %>
	<%- end -%>
}
<%- unless index == enums.count - 1 -%>

<%- end -%>
<%- end -%>
