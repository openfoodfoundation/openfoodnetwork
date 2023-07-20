# frozen_string_literal: true

require 'spec_helper'

describe Checkout::PostCheckoutActions do
  let(:order) { create(:order_with_distributor) }
  let(:postCheckoutActions) { Checkout::PostCheckoutActions.new(order) }

  describe "#success" do
    let(:params) { { order: {} } }
    let(:current_user) { order.distributor.owner }

    describe "setting customer terms_and_conditions_accepted_at" do
      before { order.customer = build(:customer) }

      it "does not set customer's terms_and_conditions to the current time " \
         "if terms have not been accepted" do
        postCheckoutActions.success(params, current_user)
        expect(order.customer.terms_and_conditions_accepted_at).to be_nil
      end

      it "sets customer's terms_and_conditions to the current time if terms have been accepted" do
        params = { order: { terms_and_conditions_accepted: true } }
        postCheckoutActions.success(params, current_user)
        expect(order.customer.terms_and_conditions_accepted_at).to_not be_nil
      end
    end

    describe "setting the user default address" do
      let(:user_default_address_setter) { instance_double(UserDefaultAddressSetter) }

      before do
        expect(UserDefaultAddressSetter).to receive(:new).
          with(order, current_user).and_return(user_default_address_setter)
      end

      it "sets user default bill address is option selected in params" do
        params[:order][:default_bill_address] = true
        expect(user_default_address_setter).to receive(:set_default_bill_address)

        postCheckoutActions.success(params, current_user)
      end

      it "sets user default ship address is option selected in params" do
        params[:order][:default_ship_address] = true
        expect(user_default_address_setter).to receive(:set_default_ship_address)

        postCheckoutActions.success(params, current_user)
      end
    end
  end

  describe "#failure" do
    let(:restart_checkout_service) { instance_double(OrderCheckoutRestart) }

    it "restarts the checkout process" do
      expect(OrderCheckoutRestart).to receive(:new).with(order).and_return(restart_checkout_service)
      expect(restart_checkout_service).to receive(:call)

      postCheckoutActions.failure
    end

    it "fixes the ship address for collection orders with the distributor's address" do
      expect(order.updater).to receive(:shipping_address_from_distributor)

      postCheckoutActions.failure
    end
  end
end
