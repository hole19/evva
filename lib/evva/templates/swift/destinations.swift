enum Destination {
	<%- destinations.each do |d| -%>
	case <%= d %>
	<%- end -%>
}
