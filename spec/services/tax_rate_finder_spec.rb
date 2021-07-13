# frozen_string_literal: true

require 'spec_helper'

describe TaxRateFinder do
  describe "getting the corresponding tax rate" do
    let(:amount) { BigDecimal(120) }
    let(:tax_rate) { create_rate(0.2) }
    let(:tax_category) { create(:tax_category, tax_rates: [tax_rate]) }
    let(:zone) { create(:zone_with_member) }
    let(:shipment) { create(:shipment) }
    let(:line_item) { create(:line_item) }
    let(:enterprise_fee) { create(:enterprise_fee, tax_category: tax_category) }
    let(:order) { create(:order_with_taxes, zone: zone) }

    it "finds the tax rate of a shipping fee" do
      rates = TaxRateFinder.new.tax_rates(tax_rate, shipment)
      expect(rates).to eq [tax_rate]
    end

    it "deals with soft-deleted tax rates" do
      tax_rate.destroy
      rates = TaxRateFinder.new.tax_rates(tax_rate, shipment)
      expect(rates).to eq [tax_rate]
    end

    it "finds the tax rate of an enterprise fee" do
      rates = TaxRateFinder.new.tax_rates(enterprise_fee, order)
      expect(rates).to eq [tax_rate]
    end

    it "deals with a soft-deleted line item" do
      line_item.destroy
      rates = TaxRateFinder.new.tax_rates(enterprise_fee, line_item)
      expect(rates).to eq [tax_rate]
    end

    def create_rate(amount)
      create(
        :tax_rate,
        amount: amount,
        calculator: Calculator::DefaultTax.new,
        zone: zone
      )
    end
  end
end
