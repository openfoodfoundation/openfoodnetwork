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
        order.update_columns(item_total: 6)

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
        # -0.0625 * 10 = -0.625
        expect(subject.included_tax.to_f).to eq(-0.63)
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

      context "when re calculating" do
        it "updates the tax adjustment" do
          order.update_columns(item_total: 200)
          tax_adjustment = order.voucher_adjustments.second

          expect do
            VoucherAdjustmentsService.calculate(order)
          end.to change { tax_adjustment.reload.amount }
        end
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
end
