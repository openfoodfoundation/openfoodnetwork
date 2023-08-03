# frozen_string_literal: true

require 'spec_helper'

describe EnterpriseFee do
  describe "associations" do
    it { is_expected.to belong_to(:enterprise).required }
    it { is_expected.to belong_to(:tax_category).optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }

    describe "requires a per-item calculator to inherit tax" do
      let(:per_order_calculators){
        [
          Calculator::FlatRate,
          Calculator::FlexiRate,
          Calculator::PriceSack,
        ]
      }

      let(:per_item_calculators){
        [
          Calculator::PerItem,
          Calculator::FlatPercentPerItem
        ]
      }

      it "is valid when inheriting tax and using a per-item calculator" do
        per_item_calculators.each do |calculator|
          subject = build(
            :enterprise_fee,
            inherits_tax_category: true,
            calculator: calculator.new
          )
          expect(subject.save).to eq true
        end
      end

      it "is invalid when inheriting tax and using a per-order calculator" do
        per_order_calculators.each do |calculator|
          subject = build(
            :enterprise_fee,
            inherits_tax_category: true,
            calculator: calculator.new
          )
          expect(subject.save).to eq false
          expect(subject.errors.full_messages.first).to eq(
            "Inheriting the tax categeory requires a per-item calculator."
          )
        end
      end
    end
  end

  describe "callbacks" do
    let(:ef) { create(:enterprise_fee) }

    it "removes itself from order cycle coordinator fees when destroyed" do
      oc = create(:simple_order_cycle, coordinator_fees: [ef])

      ef.destroy
      expect(oc.reload.coordinator_fee_ids).to be_empty
    end

    it "removes itself from order cycle exchange fees when destroyed" do
      oc = create(:simple_order_cycle)
      ex = create(:exchange, order_cycle: oc, enterprise_fees: [ef])

      ef.destroy
      expect(ex.reload.exchange_fee_ids).to be_empty
    end

    describe "for tax_category" do
      let(:tax_category) { create(:tax_category) }
      let(:enterprise_fee) {
        create(:enterprise_fee, tax_category_id: nil, inherits_tax_category: true)
      }

      it "maintains valid tax_category settings" do
        # Changing just tax_category, when inheriting
        # tax_category is changed, inherits.. set to false
        enterprise_fee.assign_attributes(tax_category_id: tax_category.id)
        enterprise_fee.save!
        expect(enterprise_fee.tax_category).to eq tax_category
        expect(enterprise_fee.inherits_tax_category).to be false

        # Changing inherits_tax_category, when tax_category is set
        # tax_category is dropped, inherits.. set to true
        enterprise_fee.assign_attributes(inherits_tax_category: true)
        enterprise_fee.save!
        expect(enterprise_fee.tax_category).to be nil
        expect(enterprise_fee.inherits_tax_category).to be true

        # Changing both tax_category and inherits_tax_category
        # tax_category is changed, but inherits.. changes are dropped
        enterprise_fee.assign_attributes(tax_category_id: tax_category.id)
        enterprise_fee.assign_attributes(inherits_tax_category: true)
        enterprise_fee.save!
        expect(enterprise_fee.tax_category).to eq tax_category
        expect(enterprise_fee.inherits_tax_category).to be false
      end
    end
  end

  describe "scopes" do
    describe "finding per-item enterprise fees" do
      it "does not return fees with FlatRate, FlexiRate and PriceSack calculators" do
        create(:enterprise_fee, calculator: Calculator::FlatRate.new)
        create(:enterprise_fee, calculator: Calculator::FlexiRate.new)
        create(:enterprise_fee, calculator: Calculator::PriceSack.new)

        expect(EnterpriseFee.per_item).to be_empty
      end

      it "returns fees with any other calculator" do
        ef1 = create(:enterprise_fee, calculator: Calculator::DefaultTax.new)
        ef2 = create(:enterprise_fee, calculator: Calculator::FlatPercentPerItem.new)
        ef3 = create(:enterprise_fee, calculator: Calculator::PerItem.new)

        expect(EnterpriseFee.per_item).to match_array [ef1, ef2, ef3]
      end
    end

    describe "finding per-order enterprise fees" do
      it "returns fees with FlatRate, FlexiRate and PriceSack calculators" do
        ef1 = create(:enterprise_fee, calculator: Calculator::FlatRate.new)
        ef2 = create(:enterprise_fee, calculator: Calculator::FlexiRate.new)
        ef3 = create(:enterprise_fee, calculator: Calculator::PriceSack.new)

        expect(EnterpriseFee.per_order).to match_array [ef1, ef2, ef3]
      end

      it "does not return fees with any other calculator" do
        ef1 = create(:enterprise_fee, calculator: Calculator::DefaultTax.new)
        ef2 = create(:enterprise_fee, calculator: Calculator::FlatPercentPerItem.new)
        ef3 = create(:enterprise_fee, calculator: Calculator::PerItem.new)

        expect(EnterpriseFee.per_order).to be_empty
      end
    end
  end

  describe "clearing all enterprise fee adjustments on an order" do
    it "clears adjustments from many fees and on all line items" do
      order_cycle = create(:order_cycle)
      order = create(:order, order_cycle: order_cycle)
      line_item1 = create(:line_item, order: order, variant: order_cycle.variants.first)
      line_item2 = create(:line_item, order: order, variant: order_cycle.variants.second)

      order_cycle.coordinator_fees[0].create_adjustment('foo1', line_item1.order, true)
      order_cycle.coordinator_fees[0].create_adjustment('foo2', line_item2.order, true)
      order_cycle.exchanges[0].enterprise_fees[0].create_adjustment('foo3', line_item1, true)
      order_cycle.exchanges[0].enterprise_fees[0].create_adjustment('foo4', line_item2, true)

      expect do
        EnterpriseFee.clear_all_adjustments order
      end.to change(order.all_adjustments, :count).by(-4)
    end

    it "clears adjustments from per-order fees" do
      order = create(:order)
      enterprise_fee = create(:enterprise_fee)
      enterprise_fee_aplicator = OpenFoodNetwork::EnterpriseFeeApplicator.new(enterprise_fee, nil,
                                                                              'coordinator')
      enterprise_fee_aplicator.create_order_adjustment(order)

      expect do
        EnterpriseFee.clear_all_adjustments order
      end.to change(order.adjustments, :count).by(-1)
    end

    it "does not clear adjustments from another originator" do
      order = create(:order)
      tax_rate = create(:tax_rate, calculator: build(:calculator))
      order.adjustments.create({ amount: 12.34,
                                 originator: tax_rate,
                                 state: 'closed',
                                 label: 'hello' })

      expect do
        EnterpriseFee.clear_all_adjustments order
      end.to change(order.adjustments, :count).by(0)
    end
  end

  describe "soft-deletion" do
    let(:tax_category) { create(:tax_category) }
    let(:enterprise_fee) { create(:enterprise_fee, tax_category: tax_category ) }
    let!(:adjustment) { create(:adjustment, originator: enterprise_fee) }

    before do
      enterprise_fee.destroy
      enterprise_fee.reload
    end

    it "soft-deletes the enterprise fee" do
      expect(enterprise_fee.deleted_at).to_not be_nil
    end

    it "can be accessed by old adjustments" do
      expect(adjustment.reload.originator).to eq enterprise_fee
      expect(adjustment.originator.tax_category).to eq enterprise_fee.tax_category
    end
  end
end
