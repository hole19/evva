enum Property: String {
	<%- properties.each do |p| -%>
	case <%= p[:case_name] %> = "<%= p[:property_name ] %>"
	<%- end -%>
}
