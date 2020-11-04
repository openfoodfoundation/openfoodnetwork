# frozen_string_literal: true

require 'spec_helper'

describe Spree::ProductProperty do
  context "validations" do
    it "should validate length of value" do
      pp = create(:product_property)
      pp.value = "x" * 256
      expect(pp).to_not be_valid
    end
  end
end
