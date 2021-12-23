struct EventData {
	let name: String
	var properties: [String: Any]?
	let destinations: [Destination]

	init(name: String, properties: [String: Any]?, destinations: [Destination]) {
		self.name = name
		self.properties = properties
		self.destinations = destinations
	}

	init(type: EventType, properties: [String: Any]?) {
		self.init(name: type.name, properties: properties, destinations: type.destinations)
	}
}

enum EventType: String {
	<%- events.each do |e| -%>
	case <%= e[:case_name] %> = "<%= e[:event_name] %>"
	<%- end -%>

	var name: String { return rawValue }

	var destinations: [Destination] {
		switch self {
		<%- events.each do |e| -%>
		case .<%= e[:case_name] %>: return [<%= e[:destinations].map { |d| ".#{d}" }.join(", ") %>]
		<%- end -%>
		}
	}
}

enum Event {
	<%- events.each do |e| -%>
	<%- if e[:properties].count == 0 -%>
	case <%= e[:case_name] %>
	<%- else -%>
	case <%= e[:case_name] %>(<%= e[:properties].map { |p| "#{p[:name]}: #{p[:type]}" }.join(", ") %>)
	<%- end -%>
	<%- end -%>

	var data: EventData {
		switch self {
		<%- events.each_with_index do |e, index| -%>
		<%- if e[:properties].count == 0 -%>
		case .<%= e[:case_name] %>:
		<%- else -%>
		case let .<%= e[:case_name] %>(<%= e[:properties].map { |p| p[:name] }.join(", ") %>):
		<%- end -%>
			return EventData(type: .<%= e[:case_name] %>,
				<%- if e[:properties].count == 0 -%>
							 properties: nil)
				<%- else -%>
							 properties: [
					<%- e[:properties].each do |p| -%>
								"<%= p[:name] %>": <%= p[:value] %> as Any,
					<%- end -%>
							 ])
				<%- end -%>
				<%- unless index == events.count - 1 -%>

				<%- end -%>
		<%- end -%>
		}
	}
}
