enum class <%= class_name %>(val key: String) {
	<%- events.each_with_index do |event, index| -%>
	<%= event[:name] %>("<%= event[:value] %>"),
	<%- end -%>
}
