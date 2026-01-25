# frozen_string_literal: true

RSpec.describe Spree::ProductProperty do
  context "validations" do
    it "should validate length of value" do
      pp = create(:product_property)
      pp.value = "x" * 256
      expect(pp).not_to be_valid
    end
  end
end
