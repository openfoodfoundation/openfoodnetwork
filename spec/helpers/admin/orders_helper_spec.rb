# frozen_string_literal: true

require "spec_helper"

describe Admin::OrdersHelper, type: :helper do
  describe "#order_adjustments_for_display" do
    let(:order) { create(:order) }
    let(:service) { instance_double(VoucherAdjustmentsService, voucher_included_tax:) }
    let(:voucher_included_tax) { 0.0 }

    before do
      allow(VoucherAdjustmentsService).to receive(:new).and_return(service)
    end

    it "selects eligible adjustments" do
      adjustment = create(:adjustment, order:, adjustable: order, amount: 1)

      expect(helper.order_adjustments_for_display(order)).to eq [adjustment]
    end

    it "filters shipping method adjustments" do
      create(:adjustment, order:, adjustable: build(:shipment), amount: 1,
                          originator_type: "Spree::ShippingMethod")

      expect(helper.order_adjustments_for_display(order)).to eq []
    end

    it "filters ineligible payment adjustments" do
      create(:adjustment, adjustable: build(:payment), amount: 0, eligible: false,
                          originator_type: "Spree::PaymentMethod", order:)

      expect(helper.order_adjustments_for_display(order)).to eq []
    end

    it "filters out line item adjustments" do
      create(:adjustment, adjustable: build(:line_item), amount: 0, eligible: false,
                          originator_type: "EnterpriseFee", order:)

      expect(helper.order_adjustments_for_display(order)).to eq []
    end

    context "with a voucher with tax included in price" do
      let(:enterprise) { build(:enterprise) }
      let(:voucher) do
        create(:voucher_flat_rate, code: 'new_code', enterprise:, amount: 10)
      end
      let(:voucher_included_tax) { -0.5 }

      it "includes a fake tax voucher adjustment" do
        voucher_adjustment = voucher.create_adjustment(voucher.code, order)
        voucher_adjustment.update(included_tax: voucher_included_tax)

        fake_adjustment = helper.order_adjustments_for_display(order).last
        expect(fake_adjustment.label).to eq("new_code (tax included in price)")
        expect(fake_adjustment.amount).to eq(-0.5)
      end
    end
  end
end
