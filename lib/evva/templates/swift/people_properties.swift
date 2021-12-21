struct PropertyData {
	let name: String
	let value: Any
	let destinations: [Destination]

	init(name: String, value: Any, destinations: [Destination]) {
		self.name = name
		self.value = value
		self.destinations = destinations
	}

	init(name: PropertyName, value: Any, destinations: [Destination]) {
		self.init(name: name.rawValue, value: value, destinations: destinations)
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
			<%- if p[:destinations].count == 0 -%>
								destinations: [])
			<%- else -%>
								destinations: [
				<%- p[:destinations].each do |d| -%>
									.<%= d %>,
				<%- end -%>
								])
			<%- end -%>
			<%- unless index == properties.count - 1 -%>

			<%- end -%>
		<%- end -%>
		}
	}
}
