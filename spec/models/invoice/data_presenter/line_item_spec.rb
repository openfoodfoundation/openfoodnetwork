# frozen_string_literal: true

RSpec.describe Invoice::DataPresenter::LineItem do
  subject(:presenter) { described_class.new(data) }

  describe "#amount_with_adjustments_without_taxes" do
    let(:data) do
      {
        price_with_adjustments: 10.0,
        quantity: 2,
        included_tax: 0.0,
        enterprise_fee_included_tax: nil
      }
    end

    it "calculated line item price" do
      expect(presenter.amount_with_adjustments_without_taxes).to eq(20.00)
    end

    context "with tax included in price" do
      let(:data) do
        {
          price_with_adjustments: 10.0,
          quantity: 2,
          included_tax: 1.0,
          enterprise_fee_included_tax: nil
        }
      end

      it "removes the included tax" do
        expect(presenter.amount_with_adjustments_without_taxes).to eq(19)
      end

      context "with enterprise fee" do
        let(:data) do
          {
            price_with_adjustments: 10.0,
            quantity: 2,
            included_tax: 0.0,
            enterprise_fee_included_tax: 0.5
          }
        end

        it "removes the enterpise fee tax" do
          expect(presenter.amount_with_adjustments_without_taxes).to eq(19.5)
        end
      end
    end
  end

  describe "#amount_with_adjustments_and_with_taxes" do
    let(:data) do
      {
        price_with_adjustments: 10.0,
        quantity: 2,
        added_tax: 0.0,
        enterprise_fee_additional_tax: nil
      }
    end

    it "cacluated the line item price with tax" do
      expect(presenter.amount_with_adjustments_and_with_taxes).to eq(20.00)
    end

    context "with tax excluded from price" do
      let(:data) do
        {
          price_with_adjustments: 10.0,
          quantity: 2,
          added_tax: 1.0,
          enterprise_fee_additional_tax: nil
        }
      end

      it "includes the added tax" do
        expect(presenter.amount_with_adjustments_and_with_taxes).to eq(21.00)
      end

      context "with enterprise fee" do
        let(:data) do
          {
            price_with_adjustments: 10.0,
            quantity: 2,
            added_tax: 0.0,
            enterprise_fee_additional_tax: 0.5
          }
        end

        it "adds the enterpise fee tax" do
          expect(presenter.amount_with_adjustments_and_with_taxes).to eq(20.50)
        end
      end
    end
  end

  # TODO
  describe "#single_display_amount_with_adjustments" do
    let(:data) do
      {
        price_with_adjustments: 10.0,
        quantity: 2,
        included_tax: 0.0,
        enterprise_fee_included_tax: nil,
        currency: "AUD"
      }
    end

    it "displays single price with adjustments" do
      expect(presenter.single_display_amount_with_adjustments).to eq(Spree::Money.new(10.0))
    end

    context "with included tax" do
      let(:data) do
        {
          price_with_adjustments: 10.0,
          quantity: 2,
          included_tax: 1.0,
          enterprise_fee_included_tax: nil
        }
      end

      it "excludes the included tax" do
        expect(presenter.single_display_amount_with_adjustments).to eq(Spree::Money.new(9.5))
      end

      context "with enterpise fee" do
        let(:data) do
          {
            price_with_adjustments: 10.0,
            quantity: 2,
            included_tax: 1.0,
            enterprise_fee_included_tax: 0.5
          }
        end

        it "includes fee but remove tax portion of the fee" do
          expect(presenter.single_display_amount_with_adjustments).to eq(Spree::Money.new(9.25))
        end
      end
    end
  end
end
