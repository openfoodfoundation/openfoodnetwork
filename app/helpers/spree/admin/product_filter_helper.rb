# frozen_string_literal: true

module Spree
  module Admin
    module ProductFilterHelper
      PRODUCT_FILTER = [
        'query', 'producerFilter', 'categoryFilter', 'sorting', 'importDateFilter'
      ].freeze

      def product_filters(params)
        params.select { |k, _v| PRODUCT_FILTER.include?(k) }
      end
    end
  end
end
