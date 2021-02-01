# frozen_string_literal: true

module Sets
  class VariantOverrideSet < ModelSet
    def initialize(collection, attributes = {})
      @collection_to_delete = []
      super(VariantOverride, collection, attributes)
    end

    protected

    def process(variant_override, attributes)
      super
      @collection_to_delete << variant_override if deletable?(variant_override)
    end

    private

    attr_reader :collection_to_delete

    def deletable?(variant_override)
      variant_override.deletable? && variant_override.tag_list.empty?
    end

    def collection_to_keep
      collection - @collection_to_delete
    end
  end
end
