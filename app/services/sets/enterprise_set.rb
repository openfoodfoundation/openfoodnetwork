# frozen_string_literal: true

module Sets
  class EnterpriseSet < ModelSet
    def initialize(collection, attributes = {})
      # The bulk update form only edits existing enterprises (no "add new row" UI), so
      # any submitted id that isn't found in the collection is stale or out of scope,
      # never a genuine new record. Reject creation unconditionally rather than
      # fabricating an Enterprise without a :name, which crashes on save.
      super(Enterprise, collection, attributes, proc { true })
    end
  end
end
