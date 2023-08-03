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
    let(:tax_rate30) do
      create(:tax_rate, included_in_price: false,
                        calculator: Calculator::DefaultTax.new,
                        amount: 0.30,
                        zone: zone)
    end
    let(:tax_category10) { create(:tax_category, tax_rates: [tax_rate10]) }
    let(:tax_category15) { create(:tax_category, tax_rates: [tax_rate15]) }
    let(:tax_category20) { create(:tax_category, tax_rates: [tax_rate20]) }
    let(:tax_category25) { create(:tax_category, tax_rates: [tax_rate25]) }
    let(:tax_category30) { create(:tax_category, tax_rates: [tax_rate30]) }

    let(:variant) { create(:variant, tax_category: tax_category10) }
    let(:enterprise_fee) do
      create(:enterprise_fee, enterprise: coordinator,
                              tax_category: tax_category20,
                              calculator: Calculator::FlatRate.new(preferred_amount: 48.0))
    end
    let(:admin_adjustment) do
      create(:adjustment, order: order, amount: 50.0, tax_category: tax_category25,
                          label: "Admin Adjustment").tap do |adjustment|
                            Spree::TaxRate.adjust(order, [adjustment])
                          end
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
        distributor: coordinator,
        state: 'payment'
      )
    end
    let(:shipping_method) do
      create(:shipping_method, calculator: Calculator::FlatRate.new(preferred_amount: 46.0),
                               tax_category: tax_category15)
    end
    let!(:shipment) do
      create(:shipment_with, :shipping_method, shipping_method: shipping_method, order: order)
    end
    let(:legacy_tax_adjustment) do
      create(:adjustment, order: order, adjustable: order, amount: 1.23, originator: tax_rate30,
                          label: "Additional Tax Adjustment", state: "closed")
    end

    before do
      order.reload
      order.adjustments << admin_adjustment
      order.recreate_all_fees!
      order.create_tax_charge!
      legacy_tax_adjustment
    end

    subject { OrderTaxAdjustmentsFetcher.new(order).totals }

    it "returns a hash with all 5 taxes" do
      expect(subject.size).to eq(5)
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

    it "contains (legacy) additional taxes recorded on the order" do
      expect(subject[tax_rate30]).to eq(1.23)
    end
  end
end
