# frozen_string_literal: true

require 'spec_helper'
require 'open_food_network/enterprise_fee_applicator'

module OpenFoodNetwork
  describe EnterpriseFeeApplicator do
    it "creates an adjustment for a line item" do
      line_item = create(:line_item)
      enterprise_fee = create(:enterprise_fee)
      product = create(:simple_product)

      efa = EnterpriseFeeApplicator.new enterprise_fee, product.master, 'role'
      allow(efa).to receive(:line_item_adjustment_label) { 'label' }
      efa.create_line_item_adjustment line_item

      adjustment = Spree::Adjustment.last
      expect(adjustment.label).to eq('label')
      expect(adjustment.adjustable).to eq(line_item)
      expect(adjustment.source).to eq(line_item)
      expect(adjustment.originator).to eq(enterprise_fee)
      expect(adjustment).to be_mandatory

      md = adjustment.metadata
      expect(md.enterprise).to eq(enterprise_fee.enterprise)
      expect(md.fee_name).to eq(enterprise_fee.name)
      expect(md.fee_type).to eq(enterprise_fee.fee_type)
      expect(md.enterprise_role).to eq('role')
    end

    it "creates an adjustment for an order" do
      order = create(:order)
      enterprise_fee = create(:enterprise_fee)
      product = create(:simple_product)

      efa = EnterpriseFeeApplicator.new enterprise_fee, nil, 'role'
      allow(efa).to receive(:order_adjustment_label) { 'label' }
      efa.create_order_adjustment order

      adjustment = Spree::Adjustment.last
      expect(adjustment.label).to eq('label')
      expect(adjustment.adjustable).to eq(order)
      expect(adjustment.source).to eq(order)
      expect(adjustment.originator).to eq(enterprise_fee)
      expect(adjustment).to be_mandatory

      md = adjustment.metadata
      expect(md.enterprise).to eq(enterprise_fee.enterprise)
      expect(md.fee_name).to eq(enterprise_fee.name)
      expect(md.fee_type).to eq(enterprise_fee.fee_type)
      expect(md.enterprise_role).to eq('role')
    end

    it "makes an adjustment label for a line item" do
      variant = double(:variant, product: double(:product, name: 'Bananas'))
      enterprise_fee = double(:enterprise_fee, fee_type: 'packing', enterprise: double(:enterprise, name: 'Ballantyne'))

      efa = EnterpriseFeeApplicator.new enterprise_fee, variant, 'distributor'

      expect(efa.send(:line_item_adjustment_label)).to eq("Bananas - packing fee by distributor Ballantyne")
    end

    it "makes an adjustment label for an order" do
      enterprise_fee = double(:enterprise_fee, fee_type: 'packing', enterprise: double(:enterprise, name: 'Ballantyne'))

      efa = EnterpriseFeeApplicator.new enterprise_fee, nil, 'distributor'

      expect(efa.send(:order_adjustment_label)).to eq("Whole order - packing fee by distributor Ballantyne")
    end
  end
end
