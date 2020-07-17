# frozen_string_literal: true

require 'spec_helper'

describe Spree::Admin::ProductFilterHelper, type: :helper do
  describe 'product_filters' do
    it 'should return only parameters included in PRODUCT_FILTER' do
      parameters = { 'query' => 'test', 'categoryFilter' => 2, 'randomFilter' => 5 }

      filters = helper.product_filters(parameters)

      puts filters.inspect
      expect(filters.key?('query')).to be true
      expect(filters.key?('categoryFilter')).to be true
      expect(filters.key?('randomFilter')).to be false
    end
  end
end
