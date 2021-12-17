enum Platform {
	<%- platforms.each do |p| -%>
	case <%= p %>
	<%- end -%>
}
