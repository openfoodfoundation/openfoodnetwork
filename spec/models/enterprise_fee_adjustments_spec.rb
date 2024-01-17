# frozen_string_literal: true

require 'spec_helper'

describe EnterpriseFeeAdjustments do
  describe "#tax" do
    let(:tax_rate) { create(:tax_rate, amount: 0.1) }
    let(:line_item) { create(:line_item) }
    let(:enterprise_fee) { create(:enterprise_fee, tax_category: tax_rate.tax_category) }
    let(:fee_adjustment) {
      create( :adjustment, originator: enterprise_fee, adjustable: line_item, state: "closed")
    }

    it "calculates total tax" do
      create(
        :adjustment, originator: tax_rate, adjustable: fee_adjustment, amount: 10.0, state: "closed"
      )

      enterprise_fee_adjustments = EnterpriseFeeAdjustments.new([fee_adjustment])

      expect(enterprise_fee_adjustments.total_tax).to eq(10.0)
    end

    context "with tax included in price" do
      it "returns 0.0" do
        create(
          :adjustment,
          originator: tax_rate,
          adjustable: fee_adjustment,
          amount: 10.0,
          state: "closed",
          included: true
        )

        enterprise_fee_adjustments = EnterpriseFeeAdjustments.new([fee_adjustment])

        expect(enterprise_fee_adjustments.total_tax).to eq(0.0)
      end
    end
  end
end
