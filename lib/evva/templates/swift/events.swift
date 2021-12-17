struct EventData {
	let name: String
	var properties: [String: Any]?
	let platforms: [Platform]

	init(name: String, properties: [String: Any]?, platforms: [Platform]) {
		self.name = name
		self.properties = properties
		self.platforms = platforms
	}

	init(name: EventName, properties: [String: Any]?, platforms: [Platform]) {
		self.init(name: name.rawValue, properties: properties, platforms: platforms)
	}
}

enum EventName: String {
	<%- events.each do |e| -%>
	case <%= e[:case_name] %> = "<%= e[:event_name] %>"
	<%- end -%>
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
			return EventData(name: .<%= e[:case_name] %>,
				<%- if e[:properties].count == 0 -%>
							 properties: nil,
				<%- else -%>
							 properties: [
					<%- e[:properties].each do |p| -%>
								"<%= p[:name] %>": <%= p[:value] %> as Any,
					<%- end -%>
							 ],
				<%- end -%>
				<%- if e[:platforms].count == 0 -%>
							 platforms: [])
				<%- else -%>
							 platforms: [
					<%- e[:platforms].each do |p| -%>
								.<%= p %>,
					<%- end -%>
							 ])
				<%- end -%>
				<%- unless index == events.count - 1 -%>

				<%- end -%>
		<%- end -%>
		}
	}
}
