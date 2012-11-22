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

  def angular_select(method, choices, angular_field, options = {}, html_options = {})
    @template.select_tag method, @template.angular_options_for_select(choices, angular_field)
  end
end
