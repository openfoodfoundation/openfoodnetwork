# frozen_string_literal: true

require 'spec_helper'

describe Spree::Asset do
  describe "#viewable" do
    it "touches association" do
      product = create(:product)
      asset = Spree::Asset.create! { |a| a.viewable = product }

      product.update_column(:updated_at, 1.day.ago)

      expect do
        asset.touch
      end.to change { product.reload.updated_at }
    end
  end
end
