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

  describe "#full_product_name" do
    let(:data) do
      {
        product_name:,
        variant: {
          display_name: "Changed Display",
          product: { name: "Changed Product" }
        }
      }
    end

    context "with a snapshotted product name" do
      let(:product_name) { "Apple" }

      it "returns the snapshotted product name" do
        expect(presenter.full_product_name).to eq("Apple")
      end
    end

    context "without a snapshotted product name" do
      let(:data) do
        {
          variant: {
            display_name: "Pink Lady",
            product: { name: "Apple" }
          }
        }
      end

      it "falls back to the invoice's product name" do
        expect(presenter.full_product_name).to eq("Apple")
      end
    end
  end

  describe "#name_to_display" do
    let(:data) do
      {
        product_name:,
        variant_display_name:,
        variant: {
          display_name:,
          product: { name: "Changed Product" }
        }
      }
    end

    context "when a variant display name was snapshotted" do
      let(:product_name) { "Apple" }
      let(:variant_display_name) { "Pink Lady" }
      let(:display_name) { "Renamed Variant" }

      it "returns the snapshotted variant display name, not the renamed one" do
        expect(presenter.name_to_display).to eq("Pink Lady")
      end
    end

    context "when a blank variant display name was snapshotted" do
      let(:product_name) { "Apple" }
      let(:variant_display_name) { "" }
      let(:display_name) { "Renamed Variant" }

      it "returns the blank snapshot, not the renamed variant" do
        expect(presenter.name_to_display).to eq("")
      end
    end

    context "when no variant display name was snapshotted and the variant has a display name" do
      let(:product_name) { "Apple" }
      let(:variant_display_name) { nil }
      let(:display_name) { "Pink Lady" }

      it "returns the variant display name" do
        expect(presenter.name_to_display).to eq("Pink Lady")
      end
    end

    context "when no variant display name was snapshotted and the variant display name is blank" do
      let(:product_name) { "Apple" }
      let(:variant_display_name) { nil }
      let(:display_name) { "" }

      it "returns the snapshotted product name, not the renamed product" do
        expect(presenter.name_to_display).to eq("Apple")
      end
    end

    context "when nothing was snapshotted and the variant display name is blank" do
      let(:product_name) { nil }
      let(:variant_display_name) { nil }
      let(:display_name) { "" }

      it "falls back to the product name" do
        expect(presenter.name_to_display).to eq("Changed Product")
      end
    end
  end
end
