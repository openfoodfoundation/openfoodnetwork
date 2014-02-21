require 'open_food_network/enterprise_fee_applicator'

module OpenFoodNetwork
  describe EnterpriseFeeApplicator do
    it "creates an adjustment for a line item" do
      line_item = create(:line_item)
      enterprise_fee = create(:enterprise_fee)
      product = create(:simple_product)

      efa = EnterpriseFeeApplicator.new enterprise_fee, product.master, 'role'
      efa.stub(:adjustment_label) { 'label' }
      efa.create_line_item_adjustment line_item

      adjustment = Spree::Adjustment.last
      adjustment.label.should == 'label'
      adjustment.adjustable.should == line_item.order
      adjustment.source.should == line_item
      adjustment.originator.should == enterprise_fee
      adjustment.should be_mandatory

      md = adjustment.metadata
      md.enterprise.should == enterprise_fee.enterprise
      md.fee_name.should == enterprise_fee.name
      md.fee_type.should == enterprise_fee.fee_type
      md.enterprise_role.should == 'role'
    end

    it "makes adjustment labels" do
      variant = double(:variant, product: double(:product, name: 'Bananas'))
      enterprise_fee = double(:enterprise_fee, fee_type: 'packing', enterprise: double(:enterprise, name: 'Ballantyne'))

      efa = EnterpriseFeeApplicator.new enterprise_fee, variant, 'distributor'

      efa.send(:adjustment_label).should == "Bananas - packing fee by distributor Ballantyne"
    end
  end
end
