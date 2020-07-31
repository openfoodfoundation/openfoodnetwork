# frozen_string_literal: true

class ProductFilters
  PRODUCT_FILTERS = [
    'query', 'producerFilter', 'categoryFilter', 'sorting', 'importDateFilter'
  ].freeze

  def extract(params)
    params.select { |key, _value| PRODUCT_FILTERS.include?(key) }
  end
end
