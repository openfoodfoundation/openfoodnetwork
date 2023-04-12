# frozen_string_literal: true

require 'spec_helper'

describe Voucher do
  let(:enterprise) { build(:enterprise) }

  describe 'associations' do
    it { is_expected.to belong_to(:enterprise) }
    it { is_expected.to have_many(:adjustments) }
  end

  describe 'validations' do
    subject { Voucher.new(code: 'new_code', enterprise: enterprise) }

    it { is_expected.to validate_presence_of(:code) }
    it { is_expected.to validate_uniqueness_of(:code).scoped_to(:enterprise_id) }
  end

  describe 'after_save' do
    subject { Voucher.create(code: 'new_code', enterprise: enterprise) }

    it 'adds a FlateRate calculator' do
      expect(subject.calculator.instance_of?(Calculator::FlatRate)).to be(true)
    end

    it 'has a preferred_amount of -10' do
      expect(subject.calculator.preferred_amount.to_f).to eq(-10)
    end
  end

  describe '.adjust!' do
    let(:voucher) { Voucher.create(code: 'new_code', enterprise: enterprise) }

    context 'when voucher covers the order total' do
      subject { order.voucher_adjustments.first }

      let(:order) { create(:order_with_totals) }

      it 'updates the adjustment amount to -order.total' do
        voucher.create_adjustment(voucher.code, order)

        order.total = 6
        order.save!

        Voucher.adjust!(order)

        expect(subject.amount.to_f).to eq(-6.0)
      end
    end

    context 'with price included in order price' do
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

        Voucher.adjust!(order)
      end

      it 'updates the adjustment included_tax' do
        # voucher_rate = amount / order.total
        # -10 / 150 = -0.066666667
        # included_tax = voucher_rate * order.included_tax_total
        # -0.66666666 * 10 = -0.67
        expect(subject.included_tax.to_f).to eq(-0.67)
      end

      it 'moves the adjustment state to closed' do
        expect(subject.state).to eq('closed')
      end
    end

    context 'with price not included in order price' do
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

        Voucher.adjust!(order)
      end

      it 'includes amount withou tax' do
        adjustment = order.voucher_adjustments.first
        # voucher_rate = amount / order.total
        # -10 / 161 = -0.062111801
        # amount = voucher_rate * (order.total - order.additional_tax_total)
        # -0.062111801 * (161 -11) = -9.32
        expect(adjustment.amount.to_f).to eq(-9.32)
      end

      it 'creates a tax adjustment' do
        # voucher_rate = amount / order.total
        # -10 / 161 = -0.062111801
        # amount = voucher_rate * order.additional_tax_total
        # -0.0585 * 11 = -0.68
        tax_adjustment = order.voucher_adjustments.second
        expect(tax_adjustment.amount.to_f).to eq(-0.68)
        expect(tax_adjustment.label).to match("Tax")
      end

      it 'moves the adjustment state to closed' do
        adjustment = order.voucher_adjustments.first
        expect(adjustment.state).to eq('closed')
      end
    end

    context 'when no order given' do
      it "doesn't blow up" do
        expect { Voucher.adjust!(nil) }.to_not raise_error
      end
    end

    context 'when no voucher used on the given order' do
      let(:order) { create(:order_with_line_items, line_items_count: 1, distributor: enterprise) }

      it "doesn't blow up" do
        expect { Voucher.adjust!(order) }.to_not raise_error
      end
    end
  end

  describe '#compute_amount' do
    subject { Voucher.create(code: 'new_code', enterprise: enterprise) }

    let(:order) { create(:order_with_totals) }

    it 'returns -10' do
      expect(subject.compute_amount(order).to_f).to eq(-10)
    end

    context 'when order total is smaller than 10' do
      it 'returns minus the order total' do
        order.total = 6
        order.save!

        expect(subject.compute_amount(order).to_f).to eq(-6)
      end
    end
  end

  describe '#create_adjustment' do
    subject(:adjustment) { voucher.create_adjustment(voucher.code, order) }

    let(:voucher) { Voucher.create(code: 'new_code', enterprise: enterprise) }
    let(:order) { create(:order_with_line_items, line_items_count: 1, distributor: enterprise) }

    it 'includes the full voucher amount' do
      expect(adjustment.amount.to_f).to eq(-10.0)
    end

    it 'has no included_tax' do
      expect(adjustment.included_tax.to_f).to eq(0.0)
    end

    it 'sets the adjustment as open' do
      expect(adjustment.state).to eq("open")
    end
  end
end
