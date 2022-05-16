# frozen_string_literal: true

module Reporting
  module Reports
    module ProductsAndInventory
      class AllProducts < Base
        def filter_on_hand(variants)
          variants # do not filter
        end
      end
    end
  end
end
