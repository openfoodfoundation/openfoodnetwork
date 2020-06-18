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

  # Since Rails 4 has adjusted the way assets paths are handled, we have to access certain
  # asset-based helpers like this, when outside of a view or controller context.
  # See: https://stackoverflow.com/a/16609815
  def image_path(path)
    ActionController::Base.helpers.image_path(path)
  end
end
