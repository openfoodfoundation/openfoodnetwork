require 'spec_helper'

describe EnterpriseFee do
  describe "associations" do
    it { should belong_to(:enterprise) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
  end

  describe "callbacks" do
    it "removes itself from order cycle coordinator fees when destroyed" do
      ef = create(:enterprise_fee)
      oc = create(:simple_order_cycle, coordinator_fees: [ef])

      ef.destroy
      oc.reload.coordinator_fee_ids.should be_empty
    end

    it "removes itself from order cycle exchange fees when destroyed" do
      ef = create(:enterprise_fee)
      oc = create(:simple_order_cycle)
      ex = create(:exchange, order_cycle: oc, enterprise_fees: [ef])

      ef.destroy
      ex.reload.exchange_fee_ids.should be_empty
    end

    describe "for tax_category" do
      let(:tax_category) { create(:tax_category) }
      let(:enterprise_fee) { create(:enterprise_fee, tax_category_id: nil, inherits_tax_category: true) }


      it  "maintains valid tax_category settings" do
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
      it "does not return fees with FlatRate and FlexiRate calculators" do
        create(:enterprise_fee, calculator: Spree::Calculator::FlatRate.new)
        create(:enterprise_fee, calculator: Spree::Calculator::FlexiRate.new)

        EnterpriseFee.per_item.should be_empty
      end

      it "returns fees with any other calculator" do
        ef1 = create(:enterprise_fee, calculator: Spree::Calculator::DefaultTax.new)
        ef2 = create(:enterprise_fee, calculator: Spree::Calculator::FlatPercentItemTotal.new)
        ef3 = create(:enterprise_fee, calculator: Spree::Calculator::PerItem.new)
        ef4 = create(:enterprise_fee, calculator: Spree::Calculator::PriceSack.new)

        EnterpriseFee.per_item.should match_array [ef1, ef2, ef3, ef4]
      end
    end

    describe "finding per-order enterprise fees" do
      it "returns fees with FlatRate and FlexiRate calculators" do
        ef1 = create(:enterprise_fee, calculator: Spree::Calculator::FlatRate.new)
        ef2 = create(:enterprise_fee, calculator: Spree::Calculator::FlexiRate.new)

        EnterpriseFee.per_order.should match_array [ef1, ef2]
      end

      it "does not return fees with any other calculator" do
        ef1 = create(:enterprise_fee, calculator: Spree::Calculator::DefaultTax.new)
        ef2 = create(:enterprise_fee, calculator: Spree::Calculator::FlatPercentItemTotal.new)
        ef3 = create(:enterprise_fee, calculator: Spree::Calculator::PerItem.new)
        ef4 = create(:enterprise_fee, calculator: Spree::Calculator::PriceSack.new)

        EnterpriseFee.per_order.should be_empty
      end
    end
  end

  describe "clearing all enterprise fee adjustments for a line item" do
    it "clears adjustments originating from many different enterprise fees" do
      p = create(:simple_product)
      d1, d2 = create(:distributor_enterprise), create(:distributor_enterprise)
      pd1 = create(:product_distribution, product: p, distributor: d1)
      pd2 = create(:product_distribution, product: p, distributor: d2)
      line_item = create(:line_item, product: p)
      pd1.enterprise_fee.create_adjustment('foo1', line_item.order, line_item, true)
      pd2.enterprise_fee.create_adjustment('foo2', line_item.order, line_item, true)

      expect do
        EnterpriseFee.clear_all_adjustments_for line_item
      end.to change(line_item.order.adjustments, :count).by(-2)
    end

    it "does not clear adjustments originating from another source" do
      p = create(:simple_product)
      pd = create(:product_distribution)
      line_item = create(:line_item, product: pd.product)
      tax_rate = create(:tax_rate, calculator: build(:calculator, preferred_amount: 10))
      tax_rate.create_adjustment('foo', line_item.order, line_item)

      expect do
        EnterpriseFee.clear_all_adjustments_for line_item
      end.to change(line_item.order.adjustments, :count).by(0)
    end
  end

  describe "clearing all enterprise fee adjustments on an order" do
    it "clears adjustments from many fees and on all line items" do
      order = create(:order)

      p1 = create(:simple_product)
      p2 = create(:simple_product)
      d1, d2 = create(:distributor_enterprise), create(:distributor_enterprise)
      pd1 = create(:product_distribution, product: p1, distributor: d1)
      pd2 = create(:product_distribution, product: p1, distributor: d2)
      pd3 = create(:product_distribution, product: p2, distributor: d1)
      pd4 = create(:product_distribution, product: p2, distributor: d2)
      line_item1 = create(:line_item, order: order, product: p1)
      line_item2 = create(:line_item, order: order, product: p2)
      pd1.enterprise_fee.create_adjustment('foo1', line_item1.order, line_item1, true)
      pd2.enterprise_fee.create_adjustment('foo2', line_item1.order, line_item1, true)
      pd3.enterprise_fee.create_adjustment('foo3', line_item2.order, line_item2, true)
      pd4.enterprise_fee.create_adjustment('foo4', line_item2.order, line_item2, true)

      expect do
        EnterpriseFee.clear_all_adjustments_on_order order
      end.to change(order.adjustments, :count).by(-4)
    end

    it "clears adjustments from per-order fees" do
      order = create(:order)
      ef = create(:enterprise_fee)
      efa = OpenFoodNetwork::EnterpriseFeeApplicator.new(ef, nil, 'coordinator')
      efa.create_order_adjustment(order)

      expect do
        EnterpriseFee.clear_all_adjustments_on_order order
      end.to change(order.adjustments, :count).by(-1)
    end

    it "does not clear adjustments from another originator" do
      order = create(:order)
      tax_rate = create(:tax_rate, calculator: stub_model(Spree::Calculator))
      order.adjustments.create({:amount => 12.34,
                                :source => order,
                                :originator => tax_rate,
                                :locked => true,
                                :label => 'hello' }, :without_protection => true)

      expect do
        EnterpriseFee.clear_all_adjustments_on_order order
      end.to change(order.adjustments, :count).by(0)
    end
  end
end
