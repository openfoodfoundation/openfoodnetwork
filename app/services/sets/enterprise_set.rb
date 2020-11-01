# frozen_string_literal: true

module Sets
  class EnterpriseSet < ModelSet
    def initialize(collection, attributes = {})
      super(Enterprise, collection, attributes)
    end
  end
end
