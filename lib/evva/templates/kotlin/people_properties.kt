sealed class <%= class_name %>(property: <%= enums_class_name %>) {
	val name = property.key

	open val value: Any = ""
	open val destinations: Array<<%= destinations_class_name %>> = []

	<%- properties.each_with_index do |property, index| -%>
	data class <%= property[:class_name] %>(
		val value: <%= property[:type] %>
	) : <%= class_name %>(<%= enums_class_name %>.<%= property[:property_name] %>) {
		override val value = value<% if property[:is_special_property] %>.key<% end %>
		<%- if property[:destinations].count > 0 -%>
		override val destinations = [
			<%- property[:destinations].each_with_index do |d, index| -%>
			<%= destinations_class_name %>.<%= d %><% if index < property[:destinations].count - 1 %>,<% end %>
			<%- end -%>
		]
		<%- end -%>
	}
	<%- unless index == properties.count - 1 -%>

	<%- end -%>
	<%- end -%>
}
