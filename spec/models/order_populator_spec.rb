require 'spec_helper'

module Spree
  describe OrderPopulator do
    let(:order) { double(:order, id: 123) }
    let(:currency) { double(:currency) }
    let(:params) { double(:params) }
    let(:distributor) { double(:distributor) }
    let(:order_cycle) { double(:order_cycle) }
    let(:op) { OrderPopulator.new(order, currency) }

    describe "populate" do

      it "checks that distributor can supply all products in the cart" do
        op.should_receive(:load_distributor_and_order_cycle).with(params).
          and_return([distributor, order_cycle])
        op.should_receive(:distributor_can_supply_products_in_cart).with(distributor).
          and_return(false)
        op.should_receive(:populate_without_distribution_validation).never
        op.should_receive(:set_cart_distributor_and_order_cycle).never

        op.populate(params).should be_false
        op.errors.to_a.should == ["That distributor can't supply all the products in your cart. Please choose another."]
      end

      it "doesn't set cart distributor and order cycle if populate fails" do
        op.should_receive(:load_distributor_and_order_cycle).with(params).
          and_return([distributor, order_cycle])
        op.should_receive(:distributor_can_supply_products_in_cart).with(distributor).
          and_return(true)

        op.class_eval do
          def populate_without_distribution_validation(from_hash)
            errors.add(:base, "Something went wrong.")
          end
        end

        op.should_receive(:set_cart_distributor_and_order_cycle).never

        op.populate(params).should be_false
        op.errors.to_a.should == ["Something went wrong."]
      end

      it "sets cart distributor and order cycle when populate succeeds" do
        op.should_receive(:load_distributor_and_order_cycle).with(params).
          and_return([distributor, order_cycle])
        op.should_receive(:distributor_can_supply_products_in_cart).with(distributor).
          and_return(true)
        op.should_receive(:populate_without_distribution_validation).with(params)
        op.should_receive(:set_cart_distributor_and_order_cycle).with(distributor, order_cycle)

        op.populate(params).should be_true
      end
    end

    describe "attempt_cart_add" do
      it "performs additional validations" do
        variant = double(:variant)
        quantity = 123
        Spree::Variant.stub(:find).and_return(variant)

        op.should_receive(:check_stock_levels).with(variant, quantity).and_return(true)
        op.should_receive(:check_distribution_provided_for).with(variant).and_return(true)
        op.should_receive(:check_variant_available_under_distributor).with(variant).
          and_return(true)
        order.should_receive(:add_variant).with(variant, quantity, currency)

        op.attempt_cart_add(333, quantity.to_s)
      end
    end

    describe "support" do
      describe "loading distributor and order cycle from hash" do
        it "loads distributor and order cycle when present" do
          params = {distributor_id: 1, order_cycle_id: 2}
          distributor = double(:distributor)
          order_cycle = double(:order_cycle)

          enterprise_scope = double(:enterprise_scope)
          enterprise_scope.should_receive(:find).with(1).and_return(distributor)
          Enterprise.should_receive(:is_distributor).and_return(enterprise_scope)
          OrderCycle.should_receive(:find).with(2).and_return(order_cycle)

          op.send(:load_distributor_and_order_cycle, params).should ==
            [distributor, order_cycle]
        end

        it "returns nil when not present" do
          op.send(:load_distributor_and_order_cycle, {}).should == [nil, nil]
        end
      end

      it "sets cart distributor and order cycle" do
        Spree::Order.should_receive(:find).with(order.id).and_return(order)
        order.should_receive(:set_distributor!).with(distributor)
        order.should_receive(:set_order_cycle!).with(order_cycle)

        op.send(:set_cart_distributor_and_order_cycle, distributor, order_cycle)
      end
    end

    describe "validations" do
      describe "determining if distributor can supply products in cart" do
        it "returns true if no distributor is supplied"
        it "returns true if the order can be changed to that distributor"
        it "returns false otherwise"
      end

      describe "checking distribution is provided for a variant" do
      end

      describe "checking variant is available under the distributor" do
      end

      describe "order cycle required for variant" do
      end
    end
  end
end
