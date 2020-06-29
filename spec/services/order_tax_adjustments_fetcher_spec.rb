# frozen_string_literal: true

require "spec_helper"

describe OrderTaxAdjustmentsFetcher do
  describe "#totals" do
    let(:zone)            { create(:zone_with_member) }
    let(:coordinator)     { create(:distributor_enterprise, charges_sales_tax: true) }

    let(:tax_rate10)      { create(:tax_rate, included_in_price: true, calculator: Spree::Calculator::DefaultTax.new, amount: 0.1, zone: zone) }
    let(:tax_rate15)      { create(:tax_rate, included_in_price: true, calculator: Spree::Calculator::DefaultTax.new, amount: 0.15, zone: zone) }
    let(:tax_rate20)      { create(:tax_rate, included_in_price: true, calculator: Spree::Calculator::DefaultTax.new, amount: 0.2, zone: zone) }
    let(:tax_rate25)      { create(:tax_rate, included_in_price: true, calculator: Spree::Calculator::DefaultTax.new, amount: 0.25, zone: zone) }
    let(:tax_category10)  { create(:tax_category, tax_rates: [tax_rate10]) }
    let(:tax_category15)  { create(:tax_category, tax_rates: [tax_rate15]) }
    let(:tax_category20)  { create(:tax_category, tax_rates: [tax_rate20]) }
    let(:tax_category25)  { create(:tax_category, tax_rates: [tax_rate25]) }

    let(:variant)         { create(:variant, product: create(:product, tax_category: tax_category10)) }
    let(:enterprise_fee)  { create(:enterprise_fee, enterprise: coordinator, tax_category: tax_category20, calculator: Spree::Calculator::FlatRate.new(preferred_amount: 48.0)) }
    let(:additional_adjustment) { create(:adjustment, amount: 50.0, included_tax: tax_rate25.compute_tax(50.0)) }

    let(:order_cycle)     { create(:simple_order_cycle, coordinator: coordinator, coordinator_fees: [enterprise_fee], distributors: [coordinator], variants: [variant]) }
    let(:line_item)       { create(:line_item, variant: variant, price: 44.0) }
    let(:order) do
      create(
        :order,
        line_items: [line_item],
        bill_address: create(:address),
        order_cycle: order_cycle,
        distributor: coordinator,
        adjustments: [additional_adjustment]
      )
    end

    before do
      allow(Spree::Config).to receive(:shipment_inc_vat).and_return(true)
      allow(Spree::Config).to receive(:shipping_tax_rate).and_return(tax_rate15.amount)
    end

    let(:shipping_method) { create(:shipping_method, calculator: Spree::Calculator::FlatRate.new(preferred_amount: 46.0)) }
    let!(:shipment) { create(:shipment_with, :shipping_method, shipping_method: shipping_method, order: order) }

    before do
      order.create_tax_charge!
      order.update_distribution_charge!
    end

    subject { OrderTaxAdjustmentsFetcher.new(order).totals }

    it "returns a hash with all 3 taxes" do
      expect(subject.size).to eq(4)
    end

    it "contains tax on line_item" do
      expect(subject[tax_rate10]).to eq(4.0)
    end

    it "contains tax on shipping_fee" do
      expect(subject[tax_rate15]).to eq(6.0)
    end

    it "contains tax on enterprise_fee" do
      expect(subject[tax_rate20]).to eq(8.0)
    end

    it "contains tax on order adjustment" do
      expect(subject[tax_rate25]).to eq(10.0)
    end
  end
end
