# frozen_string_literal: true

module SerializerHelper
  def ids_to_objs(ids)
    return [] if ids.blank?

    ids.map { |id| { id: id } }
  end

  # Returns an array of the fields a serializer needs from it's object
  # so we can #select only what the serializer will actually use
  def required_attributes(model, serializer)
    model_attributes = model.attribute_names
    serializer_attributes = serializer._attributes.keys.map(&:to_s)

    (serializer_attributes & model_attributes).map { |attr| "#{model.table_name}.#{attr}" }
  end
end
