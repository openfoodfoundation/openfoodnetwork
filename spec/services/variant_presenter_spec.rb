# frozen_string_literal: true

RSpec.describe VariantPresenter do
  subject(:presenter) { described_class.new(variant:, distributor:, order_cycle: ) }

  let(:variant) { build(:variant, price: 10.00) }
  let(:distributor) { instance_double(Enterprise) }
  let(:order_cycle) { instance_double(OrderCycle, coordinator: distributor) }

  describe "delegation" do
    it "uses the variant method is method not defined on the presenter" do
      expect(variant).to receive(:product).and_return(instance_double(Spree::Product)).at_least(:once)

      presenter.product
    end
  end

  describe "#price_with_fees" do
    subject(:presenter) { described_class.new(variant:, distributor:, order_cycle: ) }

    it "calls the variant price_with_fees" do
      expect(variant).to receive(:price_with_fees).with(distributor, order_cycle).and_return(5.00)

      expect(presenter.price_with_fees).to eq(5.00)
    end

    context "with an enterprise_fee_calculator" do
      subject(:presenter) {
        described_class.new(variant:, distributor:, order_cycle:, enterprise_fee_calculator:)
      }
      let(:enterprise_fee_calculator) { instance_double(OpenFoodNetwork::EnterpriseFeeCalculator) }

      it "calculates the price using the enterprise_fee_calculaltor" do
        expect(enterprise_fee_calculator).to receive(:indexed_fee_breakdown_for).with(variant)
          .and_return([fee_amount(3.00), fee_amount(2.00)])

        expect(presenter.price_with_fees).to eq(15.00)
      end

      it "calculates the fees only once" do
        expect(enterprise_fee_calculator).to receive(:indexed_fee_breakdown_for).with(variant)
          .once.and_return([fee_amount(5.00)])

        presenter.price_with_fees
        presenter.display_price_with_fees
        presenter.unit_price_price
        expect(presenter.fee_breakdown.sum(&:amount)).to eq(5.00)
      end

      def fee_amount(amount)
        OpenFoodNetwork::EnterpriseFeeCalculator::FeeAmount.new(
          fee_type: :admin, name: "Admin", amount:
        )
      end
    end
  end

  describe "#unit_price_price" do
    # describe a 2kg variant with a price of 50.00
    let(:variant) { build(:variant, variant_unit: "weight", unit_value: 2000, price: 50.00) }

    it "calculates the price per unit" do
      allow(variant).to receive(:price_with_fees).and_return(50.00)

      # Price per kilo
      expect(subject.unit_price_price).to eq(25.00)
    end

    context "when the denominator returns nil" do
      # describe a "items" variant with no unit_value
      let(:variant) { build(:variant, variant_unit: "items", unit_value: nil, price: 12.00) }

      it "returns the price" do
        allow(variant).to receive(:price_with_fees).and_return(12.00)

        expect(subject.unit_price_price).to eq(12.00)
      end
    end
  end
end
