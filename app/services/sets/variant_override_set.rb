# frozen_string_literal: true

module Sets
  class VariantOverrideSet < ModelSet
    def initialize(collection, attributes = {})
      super(VariantOverride,
            collection,
            attributes,
            nil,
            proc { |attrs, tag_list| deletable?(attrs, tag_list) } )
    end

    private

    def deletable?(attrs, tag_list)
      attrs['price'].blank? &&
        attrs['count_on_hand'].blank? &&
        attrs['default_stock'].blank? &&
        attrs['resettable'].blank? &&
        attrs['sku'].blank? &&
        attrs['on_demand'].blank? &&
        tag_list.empty?
    end

    # Overrides ModelSet method to check presence of a tag_list (which is not an attribute)
    # This method will delete VariantOverrides that have no values (see deletable? above)
    #   If the user sets all values to nil in the UI the VO will be deleted from the DB
    def collection_to_delete
      deleted = []
      collection.delete_if { |e| deleted << e if @delete_if.andand.call(e.attributes, e.tag_list) }
      deleted
    end

    def collection_to_keep
      collection.reject { |e| @delete_if.andand.call(e.attributes, e.tag_list) }
    end
  end
end
