struct PropertyData {
	let name: String
	let value: Any
	let destinations: [Destination]

	init(name: String, value: Any, destinations: [Destination]) {
		self.name = name
		self.value = value
		self.destinations = destinations
	}

	init(type: PropertyType, value: Any) {
		self.init(name: type.name, value: value, destinations: type.destinations)
	}
}

enum PropertyType: String {
	<%- properties.each do |p| -%>
	case <%= p[:case_name] %> = "<%= p[:property_name ] %>"
	<%- end -%>

	var name: String { return rawValue }

	var destinations: [Destination] {
		switch self {
		<%- properties.each_with_index do |p, index| -%>
		case .<%= p[:case_name] %>: return [<%= p[:destinations].map { |d| ".#{d}" }.join(", ") %>]
		<%- end -%>
		}
	}
}

enum Property {
	<%- properties.each do |p| -%>
	case <%= p[:case_name] %>(<%= p[:type] %>)
	<%- end -%>

	var data: PropertyData {
		switch self {
		<%- properties.each_with_index do |p, index| -%>
		case let .<%= p[:case_name] %>(value):
			return PropertyData(type: .<%= p[:case_name] %>,
								value: value<% if p[:is_special_property] %>.rawValue<% end %>)
			<%- unless index == properties.count - 1 -%>

			<%- end -%>
		<%- end -%>
		}
	}
}
