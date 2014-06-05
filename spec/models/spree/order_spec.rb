require 'spec_helper'

describe Spree::Order do
  describe "setting variant attributes" do
    it "sets attributes on line items for variants" do
      d = create(:distributor_enterprise)
      p = create(:product, :distributors => [d])

      subject.distributor = d
      subject.save!

      subject.add_variant(p.master, 1)
      subject.set_variant_attributes(p.master, {'max_quantity' => '3'})

      li = Spree::LineItem.last
      li.max_quantity.should == 3
    end

    it "does nothing when the line item is not found" do
      p = create(:simple_product)
      subject.set_variant_attributes(p.master, {'max_quantity' => '3'}.with_indifferent_access)
    end
  end

  describe "Payment methods" do
    let(:order) { build(:order, distributor: create(:distributor_enterprise)) }
    let(:pm1) { create(:payment_method, distributors: [order.distributor])}
    let(:pm2) { create(:payment_method, distributors: [])}
    
    it "finds the correct payment methods" do
      Spree::PaymentMethod.stub(:available).and_return [pm1, pm2] 
      order.available_payment_methods.include?(pm2).should == false
      order.available_payment_methods.include?(pm1).should == true
    end
    
  end

  describe "updating the distribution charge" do
    let(:order) { build(:order) }

    it "clears all enterprise fee adjustments on the order" do
      EnterpriseFee.should_receive(:clear_all_adjustments_on_order).with(subject)
      subject.update_distribution_charge!
    end

    it "ensures the correct adjustment(s) are created for the product distribution" do
      EnterpriseFee.stub(:clear_all_adjustments_on_order)
      line_item = double(:line_item)
      subject.stub(:line_items) { [line_item] }
      subject.stub(:provided_by_order_cycle?) { false }

      product_distribution = double(:product_distribution)
      product_distribution.should_receive(:create_adjustment_for).with(line_item)
      subject.stub(:product_distribution_for) { product_distribution }

      subject.update_distribution_charge!
    end

    it "skips line items that don't have a product distribution" do
      EnterpriseFee.stub(:clear_all_adjustments_on_order)
      line_item = double(:line_item)
      subject.stub(:line_items) { [line_item] }
      subject.stub(:provided_by_order_cycle?) { false }

      subject.stub(:product_distribution_for) { nil }

      subject.update_distribution_charge!
    end

    it "skips order cycle per-order adjustments for orders that don't have an order cycle" do
      EnterpriseFee.stub(:clear_all_adjustments_on_order)
      subject.stub(:line_items) { [] }

      subject.stub(:order_cycle) { nil }

      subject.update_distribution_charge!
    end

    it "ensures the correct adjustment(s) are created for order cycles" do
      EnterpriseFee.stub(:clear_all_adjustments_on_order)
      line_item = double(:line_item)
      subject.stub(:line_items) { [line_item] }
      subject.stub(:provided_by_order_cycle?) { true }

      order_cycle = double(:order_cycle)
      order_cycle.should_receive(:create_line_item_adjustments_for).with(line_item)
      order_cycle.stub(:create_order_adjustments_for)
      subject.stub(:order_cycle) { order_cycle }

      subject.update_distribution_charge!
    end

    it "ensures the correct per-order adjustment(s) are created for order cycles" do
      EnterpriseFee.stub(:clear_all_adjustments_on_order)
      subject.stub(:line_items) { [] }

      order_cycle = double(:order_cycle)
      order_cycle.should_receive(:create_order_adjustments_for).with(subject)
      subject.stub(:order_cycle) { order_cycle }

      subject.update_distribution_charge!
    end

    describe "looking up whether a line item can be provided by an order cycle" do
      it "returns true when the variant is provided" do
        v = double(:variant)
        line_item = double(:line_item, variant: v)
        order_cycle = double(:order_cycle, variants: [v])
        subject.stub(:order_cycle) { order_cycle }

        subject.send(:provided_by_order_cycle?, line_item).should be_true
      end

      it "returns false otherwise" do
        v = double(:variant)
        line_item = double(:line_item, variant: v)
        order_cycle = double(:order_cycle, variants: [])
        subject.stub(:order_cycle) { order_cycle }

        subject.send(:provided_by_order_cycle?, line_item).should be_false
      end

      it "returns false when there is no order cycle" do
        v = double(:variant)
        line_item = double(:line_item, variant: v)
        subject.stub(:order_cycle) { nil }

        subject.send(:provided_by_order_cycle?, line_item).should be_false
      end
    end

    it "looks up product distribution enterprise fees for a line item" do
      product = double(:product)
      variant = double(:variant, product: product)
      line_item = double(:line_item, variant: variant)

      product_distribution = double(:product_distribution)
      product.should_receive(:product_distribution_for).with(subject.distributor) { product_distribution }

      subject.send(:product_distribution_for, line_item).should == product_distribution
    end
  end

  describe "getting the distribution charge" do
    let(:o) { create(:order) }
    let(:li) { create(:line_item, order: o) }

    it "returns the sum of eligible enterprise fee adjustments" do
      ef = create(:enterprise_fee)
      ef.calculator.set_preference :amount, 123.45
      a = ef.create_locked_adjustment("adjustment", li.order, li, true)

      o.distribution_total.should == 123.45
    end

    it "does not include ineligible adjustments" do
      ef = create(:enterprise_fee)
      ef.calculator.set_preference :amount, 123.45
      a = ef.create_locked_adjustment("adjustment", li.order, li, true)

      a.update_column :eligible, false

      o.distribution_total.should == 0
    end

    it "does not include adjustments that do not originate from enterprise fees" do
      sm = create(:shipping_method)
      sm.calculator.set_preference :amount, 123.45
      sm.create_adjustment("adjustment", li.order, li, true)

      o.distribution_total.should == 0
    end
  end

  describe "setting the distributor" do
    it "sets the distributor when no order cycle is set" do
      d = create(:distributor_enterprise)
      subject.set_distributor! d
      subject.distributor.should == d
    end

    it "keeps the order cycle when it is available at the new distributor" do
      d = create(:distributor_enterprise)
      oc = create(:simple_order_cycle)
      create(:exchange, order_cycle: oc, sender: oc.coordinator, receiver: d, incoming: false)

      subject.order_cycle = oc
      subject.set_distributor! d

      subject.distributor.should == d
      subject.order_cycle.should == oc
    end

    it "clears the order cycle if it is not available at that distributor" do
      d = create(:distributor_enterprise)
      oc = create(:simple_order_cycle)

      subject.order_cycle = oc
      subject.set_distributor! d

      subject.distributor.should == d
      subject.order_cycle.should be_nil
    end

    it "clears the distributor when setting to nil" do
      d = create(:distributor_enterprise)
      subject.set_distributor! d
      subject.set_distributor! nil

      subject.distributor.should be_nil
    end
  end

  describe "setting the order cycle" do
    let(:oc) { create(:simple_order_cycle) }

    it "empties the cart when changing the order cycle" do
      subject.should_receive(:empty!)
      subject.set_order_cycle! oc
    end

    it "doesn't empty the cart if the order cycle is not different" do
      subject.should_not_receive(:empty!)
      subject.set_order_cycle! subject.order_cycle
    end
  
    it "sets the order cycle when no distributor is set" do
      subject.set_order_cycle! oc
      subject.order_cycle.should == oc
    end

    it "keeps the distributor when it is available in the new order cycle" do
      d = create(:distributor_enterprise)
      create(:exchange, order_cycle: oc, sender: oc.coordinator, receiver: d, incoming: false)

      subject.distributor = d
      subject.set_order_cycle! oc

      subject.order_cycle.should == oc
      subject.distributor.should == d
    end

    it "clears the distributor if it is not available at that order cycle" do
      d = create(:distributor_enterprise)

      subject.distributor = d
      subject.set_order_cycle! oc

      subject.order_cycle.should == oc
      subject.distributor.should be_nil
    end

    it "clears the order cycle when setting to nil" do
      d = create(:distributor_enterprise)
      subject.set_order_cycle! oc
      subject.distributor = d

      subject.set_order_cycle! nil

      subject.order_cycle.should be_nil
      subject.distributor.should == d
    end
  end

  context "validating distributor changes" do
    it "checks that a distributor is available when changing" do
      set_feature_toggle :order_cycles, false
      order_enterprise = FactoryGirl.create(:enterprise, id: 1, :name => "Order Enterprise")
      subject.distributor = order_enterprise
      product1 = FactoryGirl.create(:product)
      product2 = FactoryGirl.create(:product)
      product3 = FactoryGirl.create(:product)
      variant11 = FactoryGirl.create(:variant, product: product1)
      variant12 = FactoryGirl.create(:variant, product: product1)
      variant21 = FactoryGirl.create(:variant, product: product2)
      variant31 = FactoryGirl.create(:variant, product: product3)
      variant32 = FactoryGirl.create(:variant, product: product3)

      # Product Distributions
      # Order Enterprise sells product 1 and product 3
      FactoryGirl.create(:product_distribution, product: product1, distributor: order_enterprise)
      FactoryGirl.create(:product_distribution, product: product3, distributor: order_enterprise)

      # Build the current order
      line_item1 = FactoryGirl.create(:line_item, order: subject, variant: variant11)
      line_item2 = FactoryGirl.create(:line_item, order: subject, variant: variant12)
      line_item3 = FactoryGirl.create(:line_item, order: subject, variant: variant31)
      subject.reload
      subject.line_items = [line_item1,line_item2,line_item3]

      test_enterprise = FactoryGirl.create(:enterprise, id: 2, :name => "Test Enterprise")
      # Test Enterprise sells only product 1
      FactoryGirl.create(:product_distribution, product: product1, distributor: test_enterprise)

      subject.distributor = test_enterprise
      subject.should_not be_valid
      subject.errors.messages.should == {:distributor_id => ["cannot supply the products in your cart"]}
    end
  end

   describe "scopes" do
    describe "not_state" do
      it "finds only orders not in specified state" do
        o = FactoryGirl.create(:completed_order_with_totals)
        o.cancel!

        Spree::Order.not_state(:canceled).should_not include o
      end
    end
  end

  describe "shipping address prepopulation" do
    let(:distributor) { create(:distributor_enterprise) }
    let(:order) { build(:order, distributor: distributor) }

    before do
      order.ship_address = distributor.address.clone
      order.save # just to trigger our autopopulate the first time ;)
    end

    it "autopopulates the shipping address on save" do
      order.should_receive(:shipping_address_from_distributor).and_return true
      order.save
    end

    it "populates the shipping address if the shipping method doesn't require a delivery address" do
      order.shipping_method = create(:shipping_method, require_ship_address: false)
      order.ship_address.update_attribute :firstname, "will"
      order.save
      order.ship_address.firstname.should == distributor.address.firstname
    end

    it "does not populate the shipping address if the shipping method requires a delivery address" do
      order.shipping_method = create(:shipping_method, require_ship_address: true)
      order.ship_address.update_attribute :firstname, "will"
      order.save
      order.ship_address.firstname.should == "will"
    end

    it "doesn't attempt to create a shipment if the order is not yet valid" do
      order.shipping_method = create(:shipping_method, require_ship_address: false)
      #Shipment.should_not_r
      order.create_shipment!
    end
  end

end
