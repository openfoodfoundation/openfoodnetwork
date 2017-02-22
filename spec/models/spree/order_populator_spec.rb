require 'spec_helper'

module Spree
  describe OrderPopulator do
    let(:order) { double(:order, id: 123) }
    let(:currency) { double(:currency) }
    let(:params) { {} }
    let(:distributor) { double(:distributor) }
    let(:order_cycle) { double(:order_cycle) }
    let(:op) { OrderPopulator.new(order, currency) }

    context "end-to-end" do
      let(:order) { create(:order, distributor: distributor, order_cycle: order_cycle) }
      let(:distributor) { create(:distributor_enterprise) }
      let(:order_cycle) { create(:simple_order_cycle, distributors: [distributor], variants: [v]) }
      let(:op) { OrderPopulator.new(order, nil) }
      let(:v) { create(:variant) }

      describe "populate" do
        it "adds a variant" do
          op.populate({variants: {v.id.to_s => {quantity: '1', max_quantity: '2'}}}, true)
          li = order.find_line_item_by_variant(v)
          li.should be
          li.quantity.should == 1
          li.max_quantity.should == 2
          li.final_weight_volume.should == 1.0
        end

        it "updates a variant's quantity, max quantity and final_weight_volume" do
          order.add_variant v, 1, 2

          op.populate({variants: {v.id.to_s => {quantity: '2', max_quantity: '3'}}}, true)
          li = order.find_line_item_by_variant(v)
          li.should be
          li.quantity.should == 2
          li.max_quantity.should == 3
          li.final_weight_volume.should == 2.0
        end

        it "removes a variant" do
          order.add_variant v, 1, 2

          op.populate({variants: {}}, true)
          order.line_items(:reload)
          li = order.find_line_item_by_variant(v)
          li.should_not be
        end
      end
    end

    describe "populate" do
      before do
        op.should_receive(:distributor_and_order_cycle).
          and_return([distributor, order_cycle])
      end

      it "checks that distribution can supply all products in the cart" do
        op.should_receive(:distribution_can_supply_products_in_cart).
          with(distributor, order_cycle).and_return(false)

        op.populate(params).should be false
        op.errors.to_a.should == ["That distributor or order cycle can't supply all the products in your cart. Please choose another."]
      end

      it "locks the order" do
        op.stub(:distribution_can_supply_products_in_cart).and_return(true)
        order.should_receive(:with_lock)
        op.populate(params, true)
      end

      it "attempts cart add with max_quantity" do
        op.stub(:distribution_can_supply_products_in_cart).and_return true
        params = {variants: {"1" => {quantity: 1, max_quantity: 2}}}
        order.stub(:with_lock).and_yield
        op.stub(:varies_from_cart) { true }
        op.stub(:variants_removed) { [] }
        op.should_receive(:attempt_cart_add).with("1", 1, 2).and_return true
        op.populate(params, true)
      end
    end

    describe "varies_from_cart" do
      let(:variant) { double(:variant, id: 123) }

      it "returns true when item is not in cart and a quantity is specified" do
        op.should_receive(:line_item_for_variant_id).with(variant.id).and_return(nil)
        op.send(:varies_from_cart, {variant_id: variant.id, quantity: '2'}).should be true
      end

      it "returns true when item is not in cart and a max_quantity is specified" do
        op.should_receive(:line_item_for_variant_id).with(variant.id).and_return(nil)
        op.send(:varies_from_cart, {variant_id: variant.id, quantity: '0', max_quantity: '2'}).should be true
      end

      it "returns false when item is not in cart and no quantity or max_quantity are specified" do
        op.should_receive(:line_item_for_variant_id).with(variant.id).and_return(nil)
        op.send(:varies_from_cart, {variant_id: variant.id, quantity: '0'}).should be false
      end

      it "returns true when quantity varies" do
        li = double(:line_item, quantity: 1, max_quantity: nil)
        op.stub(:line_item_for_variant_id) { li }

        op.send(:varies_from_cart, {variant_id: variant.id, quantity: '2'}).should be true
      end

      it "returns true when max_quantity varies" do
        li = double(:line_item, quantity: 1, max_quantity: nil)
        op.stub(:line_item_for_variant_id) { li }

        op.send(:varies_from_cart, {variant_id: variant.id, quantity: '1', max_quantity: '3'}).should be true
      end

      it "returns false when max_quantity varies only in nil vs 0" do
        li = double(:line_item, quantity: 1, max_quantity: nil)
        op.stub(:line_item_for_variant_id) { li }

        op.send(:varies_from_cart, {variant_id: variant.id, quantity: '1'}).should be false
      end

      it "returns false when both are specified and neither varies" do
        li = double(:line_item, quantity: 1, max_quantity: 2)
        op.stub(:line_item_for_variant_id) { li }

        op.send(:varies_from_cart, {variant_id: variant.id, quantity: '1', max_quantity: '2'}).should be false
      end
    end

    describe "variants_removed" do
      it "returns the variant ids when one is in the cart but not in those given" do
        op.stub(:variant_ids_in_cart) { [123] }
        op.send(:variants_removed, []).should == [123]
      end

      it "returns nothing when all items in the cart are provided" do
        op.stub(:variant_ids_in_cart) { [123] }
        op.send(:variants_removed, [{variant_id: '123'}]).should == []
      end

      it "returns nothing when items are added to cart" do
        op.stub(:variant_ids_in_cart) { [123] }
        op.send(:variants_removed, [{variant_id: '123'}, {variant_id: '456'}]).should == []
      end

      it "does not return duplicates" do
        op.stub(:variant_ids_in_cart) { [123, 123] }
        op.send(:variants_removed, []).should == [123]
      end
    end

    describe "attempt_cart_add" do
      let(:variant) { double(:variant, on_hand: 250) }
      let(:quantity) { 123 }

      before do
        Spree::Variant.stub(:find).and_return(variant)
        VariantOverride.stub(:for).and_return(nil)
      end

      it "performs additional validations" do
        op.should_receive(:check_order_cycle_provided_for).with(variant).and_return(true)
        op.should_receive(:check_variant_available_under_distribution).with(variant).
          and_return(true)
        order.should_receive(:add_variant).with(variant, quantity, nil, currency)

        op.attempt_cart_add(333, quantity.to_s)
      end

      it "filters quantities through #quantities_to_add" do
        op.should_receive(:quantities_to_add).with(variant, 123, 123).
          and_return([5, 5])

        op.stub(:check_order_cycle_provided_for) { true }
        op.stub(:check_variant_available_under_distribution) { true }

        order.should_receive(:add_variant).with(variant, 5, 5, currency)

        op.attempt_cart_add(333, quantity.to_s, quantity.to_s)
      end

      it "removes variants which have become out of stock" do
        op.should_receive(:quantities_to_add).with(variant, 123, 123).
          and_return([0, 0])

        op.stub(:check_order_cycle_provided_for) { true }
        op.stub(:check_variant_available_under_distribution) { true }

        order.should_receive(:remove_variant).with(variant)
        order.should_receive(:add_variant).never

        op.attempt_cart_add(333, quantity.to_s, quantity.to_s)
      end
    end

    describe "quantities_to_add" do
      let(:v) { double(:variant, on_hand: 10) }

      context "when backorders are not allowed" do
        before { Spree::Config.allow_backorders = false }

        context "when max_quantity is not provided" do
          it "returns full amount when available" do
            op.quantities_to_add(v, 5, nil).should == [5, nil]
          end

          it "returns a limited amount when not entirely available" do
            op.quantities_to_add(v, 15, nil).should == [10, nil]
          end
        end

        context "when max_quantity is provided" do
          it "returns full amount when available" do
            op.quantities_to_add(v, 5, 6).should == [5, 6]
          end

          it "also returns the full amount when not entirely available" do
            op.quantities_to_add(v, 15, 16).should == [10, 16]
          end
        end
      end

      context "when backorders are allowed" do
        around do |example|
          Spree::Config.allow_backorders = true
          example.run
          Spree::Config.allow_backorders = false
        end

        it "does not limit quantity" do
          op.quantities_to_add(v, 15, nil).should == [15, nil]
        end

        it "does not limit max_quantity" do
          op.quantities_to_add(v, 15, 16).should == [15, 16]
        end
      end
    end

    describe "validations" do
      describe "determining if distributor can supply products in cart" do
        it "delegates to DistributionChangeValidator" do
          dcv = double(:dcv)
          dcv.should_receive(:can_change_to_distribution?).with(distributor, order_cycle).and_return(true)
          DistributionChangeValidator.should_receive(:new).with(order).and_return(dcv)
          op.send(:distribution_can_supply_products_in_cart, distributor, order_cycle).should be true
        end
      end

      describe "checking order cycle is provided for a variant, OR is not needed" do
        let(:variant) { double(:variant) }

        it "returns false and errors when order cycle is not provided and is required" do
          op.stub(:order_cycle_required_for).and_return true
          op.send(:check_order_cycle_provided_for, variant).should be false
          op.errors.to_a.should == ["Please choose an order cycle for this order."]
        end
        it "returns true when order cycle is provided" do
          op.stub(:order_cycle_required_for).and_return true
          op.instance_variable_set :@order_cycle,  double(:order_cycle)
          op.send(:check_order_cycle_provided_for, variant).should be true
        end
        it "returns true when order cycle is not required" do
          op.stub(:order_cycle_required_for).and_return false
          op.send(:check_order_cycle_provided_for, variant).should be true
        end
      end

      describe "checking variant is available under the distributor" do
        let(:product) { double(:product) }
        let(:variant) { double(:variant, product: product) }

        it "delegates to DistributionChangeValidator, returning true when available" do
          dcv = double(:dcv)
          dcv.should_receive(:variants_available_for_distribution).with(123, 234).and_return([variant])
          DistributionChangeValidator.should_receive(:new).with(order).and_return(dcv)
          op.instance_eval { @distributor = 123; @order_cycle = 234 }
          op.send(:check_variant_available_under_distribution, variant).should be true
          op.errors.should be_empty
        end

        it "delegates to DistributionChangeValidator, returning false and erroring otherwise" do
          dcv = double(:dcv)
          dcv.should_receive(:variants_available_for_distribution).with(123, 234).and_return([])
          DistributionChangeValidator.should_receive(:new).with(order).and_return(dcv)
          op.instance_eval { @distributor = 123; @order_cycle = 234 }
          op.send(:check_variant_available_under_distribution, variant).should be false
          op.errors.to_a.should == ["That product is not available from the chosen distributor or order cycle."]
        end
      end
    end


    describe "support" do
      describe "checking if order cycle is required for a variant" do
        it "requires an order cycle when the product has no product distributions" do
          product = double(:product, product_distributions: [])
          variant = double(:variant, product: product)
          op.send(:order_cycle_required_for, variant).should be true
        end

        it "does not require an order cycle when the product has product distributions" do
          product = double(:product, product_distributions: [1])
          variant = double(:variant, product: product)
          op.send(:order_cycle_required_for, variant).should be false
        end
      end

      it "provides the distributor and order cycle for the order" do
        order.should_receive(:distributor).and_return(distributor)
        order.should_receive(:order_cycle).and_return(order_cycle)
        op.send(:distributor_and_order_cycle).should == [distributor,
                                                         order_cycle]
      end
    end
  end
end
