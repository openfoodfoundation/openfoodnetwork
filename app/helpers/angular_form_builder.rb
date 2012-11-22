class AngularFormBuilder < ActionView::Helpers::FormBuilder
  # TODO: Use ng_ prefix, like ng_fields_for

  def angular_fields_for(record_name, *args, &block)
    # TODO: Handle nested angular_fields_for
    @fields_for_record_name = record_name
    block.call self
    @fields_for_record_name = nil
  end

  def angular_text_field(method, options = {})
    # @object_name --> "enterprise_fee_set"
    # @fields_for_record_name --> :collection
    # @object.send(@fields_for_record_name).first.class.to_s.underscore --> enterprise_fee

    name = "#{@object_name}[#{@fields_for_record_name}_attributes][{{ $index }}][#{method}]"
    id = "#{@object_name}_#{@fields_for_record_name}_attributes_{{ $index }}_#{method}"
    value = "{{ #{@object.send(@fields_for_record_name).first.class.to_s.underscore}.#{method} }}"

    @template.text_field_tag name, value, :id => id
  end

  def angular_select(method, choices, options = {}, html_options = {})
    # ...
  end

  def angular_options_for_select(container, selected = nil)
    return container if String === container

    selected, disabled = extract_selected_and_disabled(selected).map do | r |
      Array.wrap(r).map { |item| item.to_s }
    end

    container.map do |element|
      html_attributes = option_html_attributes(element)
      text, value = option_text_and_value(element).map { |item| item.to_s }
      selected_attribute = %Q( ng-selected="#{selected}") if selected
      disabled_attribute = ' disabled="disabled"' if disabled && option_value_selected?(value, disabled)
      %(<option value="#{ERB::Util.html_escape(value)}"#{selected_attribute}#{disabled_attribute}#{html_attributes}>#{ERB::Util.html_escape(text)}</option>)
    end.join("\n").html_safe


  end
end
