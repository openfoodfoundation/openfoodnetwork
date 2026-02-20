# frozen_string_literal: true

RSpec.describe EnterpriseFeeAdjustments do
  let(:tax_rate) { create(:tax_rate, amount: 0.1) }
  let(:line_item) { create(:line_item) }
  let(:line_item2) { create(:line_item) }
  let(:enterprise_fee) { create(:enterprise_fee, tax_category: tax_rate.tax_category) }
  let(:fee_adjustment) {
    create( :adjustment, originator: enterprise_fee, adjustable: line_item, state: "closed")
  }
  let(:fee_adjustment2) {
    create( :adjustment, originator: enterprise_fee, adjustable: line_item, state: "closed")
  }

  describe "#total_additional_tax" do
    it "calculates total tax" do
      create(
        :adjustment,
        originator: tax_rate,
        adjustable: fee_adjustment,
        amount: 10.0,
        state: "closed",
        included: false
      )
      create(
        :adjustment,
        originator: tax_rate,
        adjustable: fee_adjustment2,
        amount: 5.0,
        state: "closed",
        included: false
      )

      enterprise_fee_adjustments = EnterpriseFeeAdjustments.new([fee_adjustment, fee_adjustment2])

      expect(enterprise_fee_adjustments.total_additional_tax).to eq(15.0)
    end

    context "with no tax adjustment" do
      it "returns 0.0" do
        enterprise_fee_adjustments = EnterpriseFeeAdjustments.new([fee_adjustment])

        expect(enterprise_fee_adjustments.total_additional_tax).to eq(0.0)
      end
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

        expect(enterprise_fee_adjustments.total_additional_tax).to eq(0.0)
      end
    end
  end

  describe "total_included_tax" do
    it "calculates total tax" do
      create(
        :adjustment,
        originator: tax_rate,
        adjustable: fee_adjustment,
        amount: 10.0,
        state: "closed",
        included: true
      )
      create(
        :adjustment,
        originator: tax_rate,
        adjustable: fee_adjustment2,
        amount: 5.0,
        state: "closed",
        included: true
      )

      enterprise_fee_adjustments = EnterpriseFeeAdjustments.new([fee_adjustment, fee_adjustment2])

      expect(enterprise_fee_adjustments.total_included_tax).to eq(15.0)
    end

    context "with no tax adjustment" do
      it "returns 0.0" do
        enterprise_fee_adjustments = EnterpriseFeeAdjustments.new([fee_adjustment])

        expect(enterprise_fee_adjustments.total_additional_tax).to eq(0.0)
      end
    end

    context "with tax excluded from price" do
      it "returns 0.0" do
        create(
          :adjustment,
          originator: tax_rate,
          adjustable: fee_adjustment,
          amount: 10.0,
          state: "closed",
          included: false
        )

        enterprise_fee_adjustments = EnterpriseFeeAdjustments.new([fee_adjustment])

        expect(enterprise_fee_adjustments.total_included_tax).to eq(0.0)
      end
    end
  end
end
