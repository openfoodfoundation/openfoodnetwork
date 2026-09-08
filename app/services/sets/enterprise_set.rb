# frozen_string_literal: true

module Sets
  class EnterpriseSet < ModelSet
    def initialize(collection, attributes = {})
      @scope = attributes.delete(:scope) || collection
      super(Enterprise, collection, attributes)
    end

    # Resolves submitted ids against `@scope` (the permission-scoped, unpaginated
    # collection) rather than the possibly wrong-page `collection` passed in above.
    # This mirrors Sets::ProductSet's "only touch submitted ids, don't care which page
    # they came from" behaviour. Unlike products, enterprises have no per-record
    # `authorize!` check downstream, so `@scope` (pre-scoped to `editable_enterprises`
    # by the controller) is what keeps a submitted id outside a manager's permissions
    # from being touched at all, instead of silently building a phantom record for it.
    def collection_attributes=(collection_attributes)
      ids = collection_attributes.values.pluck(:id).compact
      @collection = @scope.where(id: ids).to_a

      collection_attributes.each_value do |attributes|
        found_element = find_model(@collection, attributes[:id])
        process(found_element, attributes) if found_element
      end
    end
  end
end
