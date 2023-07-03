# frozen_string_literal: true

require 'spec_helper'
require 'open_food_network/enterprise_fee_applicator'

module OpenFoodNetwork
  describe EnterpriseFeeApplicator do
    let(:line_item) { create(:line_item, variant: target_variant) }
    let(:inherits_tax) { true }
    let(:enterprise_fee) {
      create(:enterprise_fee, inherits_tax_category: inherits_tax, tax_category: fee_tax_category)
    }
    let(:fee_tax_category) { nil }
    let(:tax_category) { create(:tax_category) }
    let!(:target_variant) { create(:variant, tax_category: tax_category) }
    let(:product) { variant.product }
    let(:applicator) { EnterpriseFeeApplicator.new(enterprise_fee, target_variant, 'role') }

    describe "#create_line_item_adjustment" do
      it "creates an adjustment for a line item" do
        allow(applicator).to receive(:line_item_adjustment_label) { 'label' }
        applicator.create_line_item_adjustment line_item

        adjustment = Spree::Adjustment.last
        expect(adjustment.label).to eq('label')
        expect(adjustment.adjustable).to eq(line_item)
        expect(adjustment.originator).to eq(enterprise_fee)
        expect(adjustment.tax_category).to eq(tax_category)
        expect(adjustment).to be_mandatory

        metadata = adjustment.metadata
        expect(metadata.enterprise).to eq(enterprise_fee.enterprise)
        expect(metadata.fee_name).to eq(enterprise_fee.name)
        expect(metadata.fee_type).to eq(enterprise_fee.fee_type)
        expect(metadata.enterprise_role).to eq('role')
      end
    end

    describe "#create_order_adjustment" do
      let(:inherits_tax) { false }
      let(:fee_tax_category) { tax_category }
      let(:order) { create(:order) }

      it "creates an adjustment for an order" do
        allow(applicator).to receive(:order_adjustment_label) { 'label' }
        applicator.create_order_adjustment order

        adjustment = Spree::Adjustment.last
        expect(adjustment.label).to eq('label')
        expect(adjustment.adjustable).to eq(order)
        expect(adjustment.originator).to eq(enterprise_fee)
        expect(adjustment.tax_category).to eq(tax_category)
        expect(adjustment).to be_mandatory

        metadata = adjustment.metadata
        expect(metadata.enterprise).to eq(enterprise_fee.enterprise)
        expect(metadata.fee_name).to eq(enterprise_fee.name)
        expect(metadata.fee_type).to eq(enterprise_fee.fee_type)
        expect(metadata.enterprise_role).to eq('role')
      end
    end

    describe "making labels" do
      let(:variant) { double(:variant, product: double(:product, name: 'Bananas')) }
      let(:enterprise_fee) {
        double(:enterprise_fee, name: 'packing name',
                                enterprise: double(:enterprise, name: 'Ballantyne'))
      }
      let(:applicator) { EnterpriseFeeApplicator.new enterprise_fee, variant, 'distributor' }

      describe "#line_item_adjustment_label" do
        it "makes an adjustment label for a line item" do
          expect(applicator.send(:line_item_adjustment_label)).
            to eq("Bananas - packing name fee by distributor Ballantyne")
        end
      end

      describe "#order_adjustment_label" do
        let(:applicator) { EnterpriseFeeApplicator.new enterprise_fee, nil, 'distributor' }

        it "makes an adjustment label for an order" do
          expect(applicator.send(:order_adjustment_label)).
            to eq("Whole order - packing name fee by distributor Ballantyne")
        end
      end
    end
  end
end
