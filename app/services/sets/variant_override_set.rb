# frozen_string_literal: true

module Sets
  class VariantOverrideSet < ModelSet
    def initialize(collection, attributes = {})
      @collection_to_delete = []

      super(VariantOverride,
            collection,
            attributes,
            nil,
            proc { |variant_override| deletable?(variant_override) } )
    end

    protected

    def process(variant_override, attributes)
      variant_override.assign_attributes(attributes.except(:id))
      if deletable?(variant_override)
        @collection_to_delete << variant_override
      else
        variant_override.assign_attributes(attributes.except(:id))
      end
    end

    private

    def deletable?(variant_override)
      variant_override.deletable? && variant_override.tag_list.empty?
    end

    # Overrides ModelSet method to check presence of a tag_list (which is not an attribute)
    # This method will delete VariantOverrides that have no values (see deletable? above)
    #   If the user sets all values to nil in the UI the VO will be deleted from the DB
    def collection_to_delete
      deleted = []

      if collection.is_a?(ActiveRecord::Relation)
        deleted = @collection_to_delete
      else
        collection.delete_if do |variant_override|
          deleted << variant_override if @delete_if.andand.call(variant_override)
        end
      end

      deleted
    end

    def collection_to_keep
      if collection.is_a?(ActiveRecord::Relation)
        collection - @collection_to_delete
      else
        collection.reject { |e| @delete_if.andand.call(e.attributes, e.tag_list) }
      end
    end
  end
end
