struct PropertyData {
	let name: String
	let value: Any
	let platforms: [Platform]

	init(name: String, value: Any, platforms: [Platform]) {
		self.name = name
		self.value = value
		self.platforms = platforms
	}

	init(name: PropertyName, value: Any, platforms: [Platform]) {
		self.init(name: name.rawValue, value: value, platforms: platforms)
	}
}

enum PropertyName: String {
	<%- properties.each do |p| -%>
	case <%= p[:case_name] %> = "<%= p[:property_name ] %>"
	<%- end -%>
}

enum Property {
	<%- properties.each do |p| -%>
	case <%= p[:case_name] %>(<%= p[:type] %>)
	<%- end -%>

	var data: PropertyData {
		switch self {
		<%- properties.each_with_index do |p, index| -%>
		case let .<%= p[:case_name] %>(value):
			return PropertyData(name: .<%= p[:case_name] %>,
								value: value<% if p[:is_special_property] %>.rawValue<% end %>,
			<%- if p[:platforms].count == 0 -%>
								platforms: [])
			<%- else -%>
								platforms: [
				<%- p[:platforms].each do |p| -%>
									.<%= p %>,
				<%- end -%>
								])
			<%- end -%>
			<%- unless index == properties.count - 1 -%>

			<%- end -%>
		<%- end -%>
		}
	}
}
