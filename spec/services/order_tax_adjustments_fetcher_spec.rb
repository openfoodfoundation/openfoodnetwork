# frozen_string_literal: true

require "spec_helper"

describe OrderTaxAdjustmentsFetcher do
  describe "#totals" do
    let(:zone) { create(:zone_with_member) }
    let(:coordinator) { create(:distributor_enterprise, charges_sales_tax: true) }

    let(:tax_rate10) do
      create(:tax_rate, included_in_price: true,
                        calculator: Calculator::DefaultTax.new,
                        amount: 0.1,
                        zone: zone)
    end
    let(:tax_rate15) do
      create(:tax_rate, included_in_price: true,
                        calculator: Calculator::DefaultTax.new,
                        amount: 0.15,
                        zone: zone)
    end
    let(:tax_rate20) do
      create(:tax_rate, included_in_price: true,
                        calculator: Calculator::DefaultTax.new,
                        amount: 0.2,
                        zone: zone)
    end
    let(:tax_rate25) do
      create(:tax_rate, included_in_price: true,
                        calculator: Calculator::DefaultTax.new,
                        amount: 0.25,
                        zone: zone)
    end
    let(:tax_category10) { create(:tax_category, tax_rates: [tax_rate10]) }
    let(:tax_category15) { create(:tax_category, tax_rates: [tax_rate15]) }
    let(:tax_category20) { create(:tax_category, tax_rates: [tax_rate20]) }
    let(:tax_category25) { create(:tax_category, tax_rates: [tax_rate25]) }

    let(:variant) do
      create(:variant, product: create(:product, tax_category: tax_category10))
    end
    let(:enterprise_fee) do
      create(:enterprise_fee, enterprise: coordinator,
                              tax_category: tax_category20,
                              calculator: Calculator::FlatRate.new(preferred_amount: 48.0))
    end
    let(:admin_adjustment) do
      create(:adjustment, order: order, amount: 50.0, included_tax: tax_rate25.compute_tax(50.0),
                          source: nil, label: "Admin Adjustment")
    end

    let(:order_cycle) do
      create(:simple_order_cycle, coordinator: coordinator,
                                  coordinator_fees: [enterprise_fee],
                                  distributors: [coordinator],
                                  variants: [variant])
    end
    let(:line_item1) { create(:line_item, variant: variant, price: 44.0) }
    let(:line_item2) { create(:line_item, variant: variant, price: 44.0) }
    let(:order) do
      create(
        :order,
        line_items: [line_item1, line_item2],
        bill_address: create(:address),
        order_cycle: order_cycle,
        distributor: coordinator
      )
    end

    before do
      allow(Spree::Config).to receive(:shipment_inc_vat).and_return(true)
      allow(Spree::Config).to receive(:shipping_tax_rate).and_return(tax_rate15.amount)
    end

    let(:shipping_method) do
      create(:shipping_method, calculator: Calculator::FlatRate.new(preferred_amount: 46.0))
    end
    let!(:shipment) do
      create(:shipment_with, :shipping_method, shipping_method: shipping_method, order: order)
    end

    before do
      order.reload
      order.adjustments << admin_adjustment
      order.create_tax_charge!
      order.recreate_all_fees!
    end

    subject { OrderTaxAdjustmentsFetcher.new(order).totals }

    it "returns a hash with all 4 taxes" do
      expect(subject.size).to eq(4)
    end

    it "contains tax on all line_items" do
      expect(subject[tax_rate10]).to eq(8.0)
    end

    it "contains tax on shipping_fee" do
      expect(subject[tax_rate15]).to eq(6.0)
    end

    it "contains tax on enterprise_fee" do
      expect(subject[tax_rate20]).to eq(8.0)
    end

    it "contains tax on admin adjustment" do
      expect(subject[tax_rate25]).to eq(10.0)
    end
  end
end
