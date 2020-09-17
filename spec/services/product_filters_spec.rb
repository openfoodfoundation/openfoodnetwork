# frozen_string_literal: true

require 'spec_helper'

describe ProductFilters do
  describe "extract" do
    it "should return a hash including only key from ProductFilters::PRODUCT_FILTERS" do
      params = { 'id' => 20, 'producerFilter' => 2, 'categoryFilter' => 5 }

      filters = ProductFilters.new.extract(params)

      expect(filters).not_to include 'id'
      expect(filters).to include 'producerFilter'
      expect(filters).to include 'categoryFilter'
    end
  end
end
