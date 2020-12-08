require 'spec_helper'

describe Calculator::DefaultTax do
  let!(:country) { create(:country) }
  let!(:zone) { create(:zone, name: "Country Zone", default_tax: true, zone_members: []) }
  let!(:tax_category) { create(:tax_category, tax_rates: []) }
  let!(:rate) {
    build_stubbed(:tax_rate, tax_category: tax_category, amount: 0.05, included_in_price: included_in_price)
  }
  let(:included_in_price) { false }
  let!(:calculator) { Calculator::DefaultTax.new(calculable: rate ) }
  let!(:order) { create(:order) }
  let!(:line_item) { create(:line_item, price: 10, quantity: 3, tax_category: tax_category) }
  let!(:shipment) { create(:shipment, cost: 15) }

  context "#compute" do
    context "when given an order" do
      let!(:line_item_1) { line_item }
      let!(:line_item_2) { create(:line_item, price: 10, quantity: 3, tax_category: tax_category) }

      before do
        allow(order).to receive(:line_items) { [line_item_1, line_item_2] }
      end

      context "when no line items match the tax category" do
        before do
          line_item_1.tax_category = nil
          line_item_2.tax_category = nil
        end

        it "should be 0" do
          expect(calculator.compute(order)).to eq 0
        end
      end

      context "when one item matches the tax category" do
        before do
          line_item_1.tax_category = tax_category
          line_item_2.tax_category = nil
        end

        it "should be equal to the item total * rate" do
          expect(calculator.compute(order)).to eq 1.5
        end

        context "correctly rounds to within two decimal places" do
          before do
            line_item_1.price = 10.333
            line_item_1.quantity = 1
          end

          specify do
            # Amount is 0.51665, which will be rounded to...
            expect(calculator.compute(order)).to eq 0.52
          end
        end
      end

      context "when more than one item matches the tax category" do
        it "should be equal to the sum of the item totals * rate" do
          expect(calculator.compute(order)).to eq 3
        end
      end

      context "when tax is included in price" do
        let(:included_in_price) { true }

        it "will return the deducted amount from the totals" do
          # total price including 5% tax = $60
          # ex tax = $57.14
          # 57.14 + %5 = 59.997 (or "close enough" to $60)
          # 60 - 57.14 = $2.86
          expect(calculator.compute(order).to_f).to eql 2.86
        end
      end
    end

    context "when tax is included in price" do
      let(:included_in_price) { true }

      context "when the variant matches the tax category" do
        it "should be equal to the item total * rate" do
          expect(calculator.compute(line_item)).to eq 1.43
        end
      end
    end

    context "when tax is not included in price" do
      context "when the variant matches the tax category" do
        it "should be equal to the item pre-tax total * rate" do
          expect(calculator.compute(line_item)).to eq 1.50
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
