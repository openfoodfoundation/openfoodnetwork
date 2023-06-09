# frozen_string_literal: true

require 'spec_helper'

describe VoucherAdjustmentsService do
  describe '.calculate' do
    let(:enterprise) { build(:enterprise) }
    let(:voucher) { create(:voucher, code: 'new_code', enterprise: enterprise, amount: 10) }

    context 'when voucher covers the order total' do
      subject { order.voucher_adjustments.first }

      let(:order) { create(:order_with_totals) }

      it 'updates the adjustment amount to -order.total' do
        voucher.create_adjustment(voucher.code, order)

        order.total = 6
        order.save!

        VoucherAdjustmentsService.calculate(order)

        expect(subject.amount.to_f).to eq(-6.0)
      end
    end

    context 'with tax included in order price' do
      subject { order.voucher_adjustments.first }

      let(:order) do
        create(
          :order_with_taxes,
          distributor: enterprise,
          ship_address: create(:address),
          product_price: 110,
          tax_rate_amount: 0.10,
          included_in_price: true,
          tax_rate_name: "Tax 1"
        )
      end

      before do
        # create adjustment before tax are set
        voucher.create_adjustment(voucher.code, order)

        # Update taxes
        order.create_tax_charge!
        order.update_shipping_fees!
        order.update_order!

        VoucherAdjustmentsService.calculate(order)
      end

      it 'updates the adjustment included_tax' do
        # voucher_rate = amount / order.total
        # -10 / 160 = -0.0625
        # included_tax = voucher_rate * order.included_tax_total
        # -0.625 * 10 = -0.63
        expect(subject.included_tax.to_f).to eq(-0.63)
      end

      it 'moves the adjustment state to closed' do
        expect(subject.state).to eq('closed')
      end
    end

    context 'with tax not included in order price' do
      let(:order) do
        create(
          :order_with_taxes,
          distributor: enterprise,
          ship_address: create(:address),
          product_price: 110,
          tax_rate_amount: 0.10,
          included_in_price: false,
          tax_rate_name: "Tax 1"
        )
      end

      before do
        # create adjustment before tax are set
        voucher.create_adjustment(voucher.code, order)

        # Update taxes
        order.create_tax_charge!
        order.update_shipping_fees!
        order.update_order!

        VoucherAdjustmentsService.calculate(order)
      end

      it 'includes amount without tax' do
        adjustment = order.voucher_adjustments.first
        # voucher_rate = amount / order.total
        # -10 / 171 = -0.058479532
        # amount = voucher_rate * (order.total - order.additional_tax_total)
        # -0.058479532 * (171 -11) = -9.36
        expect(adjustment.amount.to_f).to eq(-9.36)
      end

      it 'creates a tax adjustment' do
        # voucher_rate = amount / order.total
        # -10 / 171 = -0.058479532
        # amount = voucher_rate * order.additional_tax_total
        # -0.058479532 * 11 = -0.64
        tax_adjustment = order.voucher_adjustments.second
        expect(tax_adjustment.amount.to_f).to eq(-0.64)
        expect(tax_adjustment.label).to match("Tax")
      end

      it 'moves the adjustment state to closed' do
        adjustment = order.voucher_adjustments.first
        expect(adjustment.state).to eq('closed')
      end
    end

    context "when adjustment is closed" do
      subject(:voucher_adjustment) { order.voucher_adjustments.first }

      let(:order) { create(:order_with_totals) }

      it "does nothing" do
        voucher.create_adjustment(voucher.code, order)

        # Apply the voucher, which will set the voucher adjustment to "closed"
        VoucherAdjustmentsService.calculate(order)
        order.update_order!

        expect do
          VoucherAdjustmentsService.calculate(order)
        end.to_not change { voucher_adjustment.reload.updated_at }
      end
    end

    context 'when no order given' do
      it "doesn't blow up" do
        expect { VoucherAdjustmentsService.calculate(nil) }.to_not raise_error
      end
    end

    context 'when no voucher used on the given order' do
      let(:order) { create(:order_with_line_items, line_items_count: 1, distributor: enterprise) }

      it "doesn't blow up" do
        expect { VoucherAdjustmentsService.calculate(order) }.to_not raise_error
      end
    end
  end

  describe ".reset" do
    subject(:voucher_adjustment) { order.voucher_adjustments.first }

    let(:enterprise) { build(:enterprise) }
    let(:voucher) { create(:voucher, code: 'new_code', enterprise: enterprise) }
    let(:order) { create(:order_with_totals) }

    before do
      adjustment = voucher.create_adjustment(voucher.code, order)
      adjustment.amount = 12
      adjustment.save!
    end

    context "when the order has no voucher adjustment" do
      it "doesn't blow up" do
        order = create(:order_with_totals)
        expect { VoucherAdjustmentsService.reset(order) }.to_not raise_error
      end
    end

    it "set the amount to 0" do
      VoucherAdjustmentsService.reset(order)

      expect(voucher_adjustment.reload.amount.to_f).to eq(0.0)
    end

    context "when adjustment is closed" do
      before do
        voucher_adjustment.close
        VoucherAdjustmentsService.reset(order)
      end

      it "re open the adjustment" do
        expect(voucher_adjustment.reload.state).to eq("open")
      end

    end

    context "when adjustment has an included tax" do
      before do
        voucher_adjustment.included_tax = -10.0
        voucher_adjustment.save!

        VoucherAdjustmentsService.reset(order)
      end

      it "set the included_tax to 0" do
        expect(voucher_adjustment.reload.included_tax.to_f).to eq(0.0)
      end
    end

    context "when adjustment has a separate tax asjustment" do
      before do
        # Create a separate Tax asjustment
        adjustment_attributes = {
          amount: 10.0,
          originator: voucher_adjustment.originator,
          order: order,
          label: "Tax #{voucher_adjustment.label}",
          mandatory: false,
          state: 'closed',
          tax_category: nil,
          included_tax: 0
        }
        order.adjustments.create!(adjustment_attributes)
      end

      it "removes the tax adjustment" do
        expect do
          VoucherAdjustmentsService.reset(order)
        end.to change { order.voucher_adjustments.reload.count }.by(-1)

        expect(order.voucher_adjustments.where('label LIKE ?', "Tax%")).to be_empty
      end
    end
  end
end
