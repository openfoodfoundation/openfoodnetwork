# frozen_string_literal: true

module Sets
  class ColumnPreferenceSet < ModelSet
    def initialize(collection, attributes = {})
      super(ColumnPreference, collection, attributes, nil, nil )
    end
  end
end
