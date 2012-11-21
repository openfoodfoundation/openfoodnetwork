class AngularFormBuilder < ActionView::Helpers::FormBuilder
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

    @template.text_field_tag name, :id => id
  end

end
