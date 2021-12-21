enum class <%= class_name %> {
	<%- destinations.each_with_index do |destination, index| -%>
	<%= destination %><%= index == destinations.count - 1 ? ";" : "," %>
	<%- end -%>
}
