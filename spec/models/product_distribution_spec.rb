require 'spec_helper'

describe ProductDistribution do
  it "is unique for scope [product, distributor]" do
    pd1 = create(:product_distribution)
    expect(pd1).to be_valid

    new_product = create(:product)
    new_distributor = create(:distributor_enterprise)

    pd2 = build(:product_distribution, :product => pd1.product, :distributor => pd1.distributor)
    expect(pd2).to_not be_valid

    pd2 = build(:product_distribution, :product => pd1.product, :distributor => new_distributor)
    expect(pd2).to be_valid

    pd2 = build(:product_distribution, :product => new_product, :distributor => pd1.distributor)
    expect(pd2).to be_valid

    pd2 = build(:product_distribution, :product => new_product, :distributor => new_distributor)
    expect(pd2).to be_valid
  end


  describe "adjusting orders" do
    describe "finding our adjustment for a line item" do
      it "returns nil when not present" do
        line_item = build(:line_item)
        pd = ProductDistribution.new
        expect(pd.send(:adjustment_for, line_item)).to be_nil
      end

      it "returns the adjustment when present" do
        pd = create(:product_distribution)
        line_item = create(:line_item)
        adjustment = pd.enterprise_fee.create_adjustment('foo', line_item.order, line_item, true)

        expect(pd.send(:adjustment_for, line_item)).to eq adjustment
      end

      it "raises an error when there are multiple adjustments for this enterprise fee" do
        pd = create(:product_distribution)
        line_item = create(:line_item)
        pd.enterprise_fee.create_adjustment('one', line_item.order, line_item, true)
        pd.enterprise_fee.create_adjustment('two', line_item.order, line_item, true)

        expect do
          pd.send(:adjustment_for, line_item)
        end.to raise_error "Multiple adjustments for this enterprise fee on this line item. This method is not designed to deal with this scenario."
      end
    end

    describe "creating an adjustment for a line item" do
      it "creates the adjustment via the enterprise fee" do
        pd = create(:product_distribution)
        pd.stub(:adjustment_label_for) { 'label' }
        line_item = create(:line_item)

        expect { pd.send(:create_adjustment_for, line_item) }.to change(Spree::Adjustment, :count).by(1)

        adjustment = Spree::Adjustment.last
        expect(adjustment.label).to eq 'label'
        expect(adjustment.adjustable).to eq line_item.order
        expect(adjustment.source).to eq line_item
        expect(adjustment.originator).to eq pd.enterprise_fee
        expect(adjustment).to be_mandatory

        md = adjustment.metadata
        expect(md.enterprise).to eq pd.distributor
        expect(md.fee_name).to eq pd.enterprise_fee.name
        expect(md.fee_type).to eq pd.enterprise_fee.fee_type
        expect(md.enterprise_role).to eq 'distributor'
      end
    end
  end


  private

  def fire_order_contents_changed_event(user, order)
    ActiveSupport::Notifications.instrument('spree.order.contents_changed', {user: user, order: order})
  end

end
