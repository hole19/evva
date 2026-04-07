<%= @swift_public_modifier %>enum Destination {
	<%- destinations.each do |d| -%>
	case <%= d %>
	<%- end -%>
}
