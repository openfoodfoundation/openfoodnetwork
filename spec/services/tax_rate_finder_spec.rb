require 'spec_helper'

describe TaxRateFinder do
  describe "getting the corresponding tax rate" do
    let(:amount) { BigDecimal(120) }
    let(:included_tax) { BigDecimal(20) }
    let(:tax_rate) { create_rate(0.2) }
    let(:tax_category) { create(:tax_category, tax_rates: [tax_rate]) }
    let(:zone) { create(:zone_with_member) }
    let(:shipment) { create(:shipment) }
    let(:enterprise_fee) { create(:enterprise_fee, tax_category: tax_category) }
    let(:order) { create(:order_with_taxes, zone: zone) }

    it "finds the tax rate of a shipping fee" do
      rates = TaxRateFinder.new.tax_rates(
        tax_rate,
        shipment,
        amount,
        included_tax
      )
      expect(rates).to eq [tax_rate]
    end

    it "finds a close match" do
      tax_rate.destroy
      close_tax_rate = create_rate(tax_rate.amount + 0.05)
      # other tax rates, not as close to the real one
      create_rate(tax_rate.amount + 0.06)
      create_rate(tax_rate.amount - 0.06)

      rates = TaxRateFinder.new.tax_rates(
        nil,
        shipment,
        amount,
        included_tax
      )

      expect(rates).to eq [close_tax_rate]
    end

    it "finds the tax rate of an enterprise fee" do
      rates = TaxRateFinder.new.tax_rates(
        enterprise_fee,
        order,
        amount,
        included_tax
      )
      expect(rates).to eq [tax_rate]
    end

    # There is a bug that leaves orphan adjustments on an order after
    # associated line items have been removed.
    # https://github.com/openfoodfoundation/openfoodnetwork/issues/3127
    it "deals with a missing line item" do
      rates = TaxRateFinder.new.tax_rates(
        enterprise_fee,
        nil,
        amount,
        included_tax
      )
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
