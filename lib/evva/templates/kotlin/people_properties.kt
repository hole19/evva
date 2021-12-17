enum class <%= class_name %>(val key: String) {
	<%- properties.each_with_index do |properties, index| -%>
	<%= properties[:name] %>("<%= properties[:value] %>")<%= index == properties.count - 1 ? ";" : "," %>
	<%- end -%>
}
