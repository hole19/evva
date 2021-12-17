enum class <%= class_name %> {
	<%- platforms.each_with_index do |platform, index| -%>
	<%= platform %><%= index == platforms.count - 1 ? ";" : "," %>
	<%- end -%>
}
