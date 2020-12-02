require 'spec_helper'

describe Calculator::DefaultTax do
  let!(:tax_category) { create(:tax_category, tax_rates: []) }
  let!(:rate) {
    build_stubbed(:tax_rate, tax_category: tax_category, amount: 0.05, included_in_price: vat)
  }
  let(:vat) { false }
  let!(:calculator) { Calculator::DefaultTax.new(calculable: rate ) }
  let!(:order) { create(:order) }
  let!(:line_item) { create(:line_item, price: 10, quantity: 3, tax_category: tax_category) }
  let!(:shipment) { create(:shipment, cost: 15) }

  context "#compute" do
    context "when tax is included in price" do
      let(:vat) { true }

      context "when the variant matches the tax category" do
        it "should be equal to the item total * rate" do
          expect(calculator.compute(line_item)).to eq 1.43
        end
      end
    end

    context "when tax is not included in price" do
      context "when the variant matches the tax category" do
        it "should be equal to the item total * rate" do
          expect(calculator.compute(line_item)).to eq 1.50
        end
      end
    end

    context "when given a line item" do
      context "when the variant does not match the tax category" do
        before do
          allow(line_item).to receive(:tax_category) { nil }
        end

        it "should be 0" do
          expect(calculator.compute(line_item)).to eq 0
        end
      end
    end

    context "when given a shipment" do
      it "should be 5% of 15" do
        expect(calculator.compute(shipment)).to eq 0.75
      end
    end
  end
end
