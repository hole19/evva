<%- enums.each_with_index do |enum, index| -%>
enum <%= enum[:name] %>: String {
	<%- enum[:values].each do |v| -%>
	case <%= v[:case_name] %> = "<%= v[:value ] %>"
	<%- end -%>
}
<%- unless index == enums.count - 1 -%>

<%- end -%>
<%- end -%>