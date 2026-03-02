# frozen_string_literal: true

RSpec.describe TaxHelper do
  let(:line_item) { create(:line_item) }
  let(:line_item2) { create(:line_item) }
  let(:line_item3) { create(:line_item) }
  let!(:tax_rate) { create(:tax_rate, amount: 0.1) }
  let!(:tax_rate2) { create(:tax_rate, amount: 0.2, included_in_price: false) }
  let!(:included_tax_adjustment) {
    create(:adjustment, originator: tax_rate, adjustable: line_item, state: "closed")
  }
  let!(:additional_tax_adjustment) {
    create(:adjustment, originator: tax_rate2, adjustable: line_item2, state: "closed")
  }
  let!(:no_tax_adjustment) {
    create(:adjustment, amount: 0, adjustable: line_item3, state: "closed")
  }

  before do
    included_tax_adjustment.update(included: true)
  end

  describe "#display_taxes" do
    it "displays included tax" do
      expect(
        helper.display_taxes(included_tax_adjustment)
      ).to eq Spree::Money.new(included_tax_adjustment.included_tax_total)
    end

    it "displays additional tax" do
      expect(
        helper.display_taxes(additional_tax_adjustment)
      ).to eq Spree::Money.new(additional_tax_adjustment.additional_tax_total)
    end

    it "displays formatted 0.00 amount when amount is zero" do
      expect(
        helper.display_taxes(no_tax_adjustment)
      ).to eq Spree::Money.new(0.00)
    end

    it "optionally displays nothing when amount is zero" do
      expect(
        helper.display_taxes(no_tax_adjustment, display_zero: false)
      ).to be_nil
    end
  end

  describe "#display_line_items_taxes" do
    let(:enterprise_fee) { create(:enterprise_fee, tax_category: tax_rate.tax_category) }

    context "with included tax" do
      it "displays included tax" do
        expect(
          helper.display_line_items_taxes(line_item)
        ).to eq Spree::Money.new(line_item.included_tax, currency: line_item.currency)
      end

      context "with enterprise fee incuring tax" do
        let(:fee_adjustment) {
          create( :adjustment, originator: enterprise_fee, adjustable: line_item, state: "closed")
        }
        let!(:fee_tax_adjustment) {
          create(
            :adjustment,
            originator: tax_rate,
            adjustable: fee_adjustment,
            amount: 10,
            state: "closed",
            included: true
          )
        }

        it "includes enterprise fee tax" do
          expected_tax = line_item.included_tax + fee_tax_adjustment.amount
          expect(
            helper.display_line_items_taxes(line_item)
          ).to eq Spree::Money.new(expected_tax, currency: line_item.currency)
        end
      end
    end

    context "with additional tax (tax exluded from price)" do
      it "displays additional tax" do
        expect(
          helper.display_line_items_taxes(line_item2)
        ).to eq Spree::Money.new(line_item2.added_tax, currency: line_item2.currency)
      end

      context "with enterprise fee incuring tax" do
        let(:fee_adjustment) {
          create( :adjustment, originator: enterprise_fee, adjustable: line_item2, state: "closed")
        }
        let(:fee_tax_adjustment) {
          create(
            :adjustment,
            originator: tax_rate,
            adjustable: fee_adjustment,
            amount: 10,
            state: "closed",
            included: false
          )
        }

        it "includes enterprise fee tax" do
          expected_tax = line_item2.added_tax + fee_tax_adjustment.amount
          expect(
            helper.display_line_items_taxes(line_item2)
          ).to eq Spree::Money.new(expected_tax, currency: line_item2.currency)
        end
      end
    end

    it "displays formatted 0.00 amount when amount is zero" do
      expect(
        helper.display_line_items_taxes(line_item3)
      ).to eq Spree::Money.new(0.00)
    end

    it "optionally displays nothing when amount is zero" do
      expect(
        helper.display_line_items_taxes(line_item3, display_zero: false)
      ).to be_nil
    end
  end

  describe "#display_total_with_tax" do
    it "displays total with included tax" do
      expect(
        helper.display_total_with_tax(included_tax_adjustment)
      ).to eq Spree::Money.new(
        included_tax_adjustment.amount + + included_tax_adjustment.included_tax_total
      )
    end

    it "displays total with additional tax" do
      expect(
        helper.display_total_with_tax(additional_tax_adjustment)
      ).to eq Spree::Money.new(
        additional_tax_adjustment.amount + additional_tax_adjustment.additional_tax_total
      )
    end
  end
end
