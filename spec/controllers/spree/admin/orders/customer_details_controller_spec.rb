# frozen_string_literal: true

require 'spec_helper'

describe Spree::Admin::Orders::CustomerDetailsController, type: :controller do
  include AuthenticationHelper

  describe "#update" do
    context "adding customer details via newly created admin order" do
      let!(:user) { create(:user) }
      let(:address) { create(:address) }
      let!(:distributor) { create(:distributor_enterprise) }
      let!(:shipment) { create(:shipment) }
      let!(:order) {
        create(
          :order_with_totals_and_distribution,
          state: 'cart',
          shipments: [shipment],
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
        controller_login_as_enterprise_user [order.distributor]
      end

      it "advances the order state" do
        expect {
          spree_post :update, order: { email: user.email, bill_address_attributes: address_params,
                                       ship_address_attributes: address_params },
                              order_id: order.number
        }.to change { order.reload.state }.from("cart").to("payment")
      end

      context "when adding details of a registered user" do
        it "redirects to shipments on success" do
          spree_post :update,
                     order: {
                       email: user.email,
                       bill_address_attributes: address_params,
                       ship_address_attributes: address_params,
                     },
                     order_id: order.number

          order.reload

          expect(response).to redirect_to spree.admin_order_customer_path(order)
        end
      end

      context "when adding details of an unregistered user" do
        it "redirects to shipments on success" do
          spree_post :update,
                     order: {
                       email: 'unregistered@email.com',
                       bill_address_attributes: address_params,
                       ship_address_attributes: address_params,
                     },
                     order_id: order.number

          order.reload

          expect(response).to redirect_to spree.admin_order_customer_path(order)
        end
      end
    end
  end
end
