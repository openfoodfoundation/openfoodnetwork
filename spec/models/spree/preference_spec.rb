require 'spec_helper'

module Spree
  describe Preference do
    describe "refreshing the products cache" do
      it "reports when product_selection_from_inventory_only has changed" do
        p = Preference.new(key: 'enterprise/product_selection_from_inventory_only/123')
        expect(p.send(:product_selection_from_inventory_only_changed?)).to be true
      end

      it "reports when product_selection_from_inventory_only has not changed" do
        p = Preference.new(key: 'enterprise/shopfront_message/123')
        expect(p.send(:product_selection_from_inventory_only_changed?)).to be false
      end

      it "looks up the referenced enterprise" do
        e = create(:distributor_enterprise)
        p = Preference.new(key: "enterprise/product_selection_from_inventory_only/#{e.id}")
        expect(p.send(:enterprise)).to eql e
      end
    end
  end
end
