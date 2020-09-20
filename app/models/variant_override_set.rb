class VariantOverrideSet < ModelSet
  def initialize(collection, attributes = {})
    super(VariantOverride, collection, attributes, nil, proc { |attrs, tag_list| deletable?(attrs, tag_list) } )
  end

  private

  def deletable?(attrs, tag_list)
    attrs['price'].blank? &&
      attrs['count_on_hand'].blank? &&
      attrs['default_stock'].blank? &&
      attrs['resettable'].blank? &&
      attrs['sku'].nil? &&
      attrs['on_demand'].nil? &&
      tag_list.empty?
  end

  # Override of ModelSet method to allow us to check presence of a tag_list (which is not an attribute)
  # This method will delete VariantOverrides that have no values (see deletable? above)
  #   If the user sets all values to nil in the UI the VO will be deleted from the DB
  def collection_to_delete
    collection.select { |model| delete_if.call(model.attributes, model.tag_list) }
  end
end
