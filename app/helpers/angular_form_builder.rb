class AngularFormBuilder < ActionView::Helpers::FormBuilder
  # TODO: Use ng_ prefix, like ng_fields_for

  def angular_fields_for(record_name, *args, &block)
    raise "Nested angular_fields_for is not yet supported" if @fields_for_record_name.present?
    @fields_for_record_name = record_name
    block.call self
    @fields_for_record_name = nil
  end

  def angular_text_field(method, options = {})
    # @object_name --> "enterprise_fee_set"
    # @fields_for_record_name --> :collection
    # @object.send(@fields_for_record_name).first.class.to_s.underscore --> enterprise_fee

    value = "{{ #{@object.send(@fields_for_record_name).first.class.to_s.underscore}.#{method} }}"

    @template.text_field_tag angular_name(method), value, :id => angular_id(method)
  end

  def angular_hidden_field(method, options = {})
    value = "{{ #{@object.send(@fields_for_record_name).first.class.to_s.underscore}.#{method} }}"

    @template.hidden_field_tag angular_name(method), value, :id => angular_id(method)
  end

  def angular_select(method, choices, angular_field, options = {})
    options.reverse_merge!({'id' => angular_id(method)})

    @template.select_tag angular_name(method), @template.angular_options_for_select(choices, angular_field), options
  end

  def angular_collection_select(method, collection, value_method, text_method, angular_field, options = {})
    options.reverse_merge!({'id' => angular_id(method)})

    @template.select_tag angular_name(method), @template.angular_options_from_collection_for_select(collection, value_method, text_method, angular_field), options
  end

  private
  def angular_name(method)
    "#{@object_name}[#{@fields_for_record_name}_attributes][{{ $index }}][#{method}]"
  end

  def angular_id(method)
    "#{@object_name}_#{@fields_for_record_name}_attributes_{{ $index }}_#{method}"
  end
end
