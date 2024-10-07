enum class <%= class_name %>(val key: String) {
	<%- properties.each_with_index do |property, index| -%>
	<%= property[:name] %>("<%= property[:value] %>")<%= index == properties.count - 1 ? "" : "," %>
	<%- end -%>
}
