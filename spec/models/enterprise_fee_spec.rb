require 'spec_helper'

describe EnterpriseFee do
  describe "associations" do
    it { should belong_to(:enterprise) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
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
end
