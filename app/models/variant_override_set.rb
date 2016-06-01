class VariantOverrideSet < ModelSet
  def initialize(collection, attributes={})
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

  def collection_to_delete
    # Override of ModelSet method to allow us to check presence of a tag_list (which is not an attribute)
    deleted = []
    collection.delete_if { |e| deleted << e if @delete_if.andand.call(e.attributes, e.tag_list) }
    deleted
  end

  def collection_to_keep
    collection.reject { |e| @delete_if.andand.call(e.attributes, e.tag_list) }
  end
end
