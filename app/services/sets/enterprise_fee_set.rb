# frozen_string_literal: true

module Sets
  class EnterpriseFeeSet < ModelSet
    def initialize(collection, attributes = {})
      super(EnterpriseFee, collection, attributes, proc { |attrs| attrs[:name].blank? })
    end
  end
end
