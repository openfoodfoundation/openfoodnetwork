require 'spec_helper'

describe Spree::Admin::Orders::CustomerDetailsController, type: :controller do
  include AuthenticationWorkflow

  describe "#update" do
    context "adding customer details via newly created admin order" do
      let!(:user) { create(:user) }
      let(:address) { create(:address) }
      let!(:distributor) { create(:distributor_enterprise) }
      let!(:shipping_method) { create(:shipping_method) }
      let!(:order) {
        create(
            :order_with_totals_and_distribution,
            state: 'cart',
            shipping_method: shipping_method,
            distributor: distributor,
            user: nil,
            email: nil,
            bill_address: nil,
            ship_address: nil,
        )
      }
      let(:address_params) {
        {
          firstname: address.firstname,
          lastname: address.lastname,
          address1: address.address1,
          address2: address.address2,
          city: address.city,
          zipcode: address.zipcode,
          country_id: address.country_id,
          state_id: address.state_id,
          phone: address.phone
        }
      }

      before do
        login_as_enterprise_user [order.distributor]
      end

      it "accepts registered users" do
        spree_post :update, order: { email: user.email, bill_address_attributes: address_params, ship_address_attributes: address_params }, order_id: order.number

        order.reload

        expect(response).to redirect_to spree.edit_admin_order_shipment_path(order, order.shipment)
        expect(order.email).to eq user.email
        expect(order.user_id).to eq user.id
        expect(order.ship_address).to_not be_nil
      end

      it "accepts unregistered users" do
        spree_post :update, order: { email: 'unregistered@email.com', bill_address_attributes: address_params, ship_address_attributes: address_params }, order_id: order.number

        order.reload

        expect(response).to redirect_to spree.edit_admin_order_shipment_path(order, order.shipment)
        expect(order.email).to eq 'unregistered@email.com'
        expect(order.user_id).to be_nil
        expect(order.ship_address).to_not be_nil
      end
    end
  end
end
