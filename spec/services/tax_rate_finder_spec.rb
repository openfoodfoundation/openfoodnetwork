# frozen_string_literal: true

require 'spec_helper'

describe TaxRateFinder do
  describe "getting the corresponding tax rate" do
    let(:amount) { BigDecimal(120) }
    let(:tax_rate) {
      create(:tax_rate, amount: 0.2, calculator: Calculator::DefaultTax.new, zone: zone)
    }
    let(:tax_rate_shipping) {
      create(:tax_rate, amount: 0.05, calculator: Calculator::DefaultTax.new, zone: zone)
    }
    let(:tax_category) { create(:tax_category, tax_rates: [tax_rate]) }
    let(:tax_category_shipping) { create(:tax_category, tax_rates: [tax_rate_shipping]) }
    let(:zone) { create(:zone_with_member) }
    let(:shipping_method) { create(:shipping_method, tax_category: tax_category_shipping) }
    let(:shipment) { create(:shipment_with, :shipping_method, shipping_method: shipping_method) }
    let(:line_item) { create(:line_item) }
    let(:enterprise_fee) { create(:enterprise_fee, tax_category: tax_category) }
    let(:order) { create(:order_with_taxes, zone: zone) }

    subject { TaxRateFinder.new }

    it "finds the tax rate of a shipping fee" do
      rates = subject.tax_rates(tax_rate, shipment)
      expect(rates).to eq [tax_rate]
    end

    it "finds the tax rate of a shipping_method fee" do
      rates = subject.tax_rates(shipping_method, shipment)
      expect(rates).to eq [tax_rate_shipping]
    end

    it "deals with soft-deleted tax rates" do
      tax_rate.destroy
      rates = subject.tax_rates(tax_rate, shipment)
      expect(rates).to eq [tax_rate]
    end

    it "finds the tax rate of an enterprise fee" do
      rates = subject.tax_rates(enterprise_fee, order)
      expect(rates).to eq [tax_rate]
    end

    it "deals with a soft-deleted line item" do
      line_item.destroy
      rates = subject.tax_rates(enterprise_fee, line_item)
      expect(rates).to eq [tax_rate]
    end

    context "when the given adjustment has no associated tax" do
      let(:adjustment) { create(:adjustment) }

      it "returns an empty array" do
        expect(subject.tax_rates(adjustment.originator, adjustment.adjustable)).to eq []
      end
    end
  end
end
