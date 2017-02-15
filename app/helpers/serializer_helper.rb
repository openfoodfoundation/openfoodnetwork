module SerializerHelper
  def ids_to_objs(ids)
    return [] if ids.blank?
    ids.map { |id| {id: id} }
  end
end
