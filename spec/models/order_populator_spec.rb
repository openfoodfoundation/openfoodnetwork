require 'spec_helper'

module Spree
  describe OrderPopulator do
    let(:order) { double(:order) }
    let(:currency) { double(:currency) }
    let(:params) { double(:params) }
    let(:distributor) { double(:distributor) }
    let(:order_cycle) { double(:order_cycle) }

    describe "populate" do

      it "checks that distributor can supply all products in the cart" do
        op = OrderPopulator.new(order, currency)

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
        op = OrderPopulator.new(order, currency)

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
        op = OrderPopulator.new(order, currency)

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
      it "validates distribution is provided"
      it "validates variant is available under distributor"
    end

    describe "validations" do
      describe "checking distribution is provided for a variant" do
      end

      describe "checking variant is available under the distributor" do
      end

      describe "order cycle required for variant" do
      end
    end
  end
end
