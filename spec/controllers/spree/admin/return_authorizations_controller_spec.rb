# frozen_string_literal: true

require 'spec_helper'

module Spree
  module Admin
    describe ReturnAuthorizationsController, type: :controller do
      include AuthenticationHelper

      let(:order) { create(:shipped_order, distributor: create(:distributor_enterprise)) }

      before do
        controller_login_as_admin
      end

      it "creates and updates a return authorization" do
        # Create return authorization
        spree_post :create, order_id: order.number,
                            return_authorization: { amount: "20.2", reason: "broken" }

        expect(response).to redirect_to spree.admin_order_return_authorizations_url(order.number)
        return_authorization = order.return_authorizations.first
        expect(return_authorization.amount.to_s).to eq "20.2"
        expect(return_authorization.reason.to_s).to eq "broken"

        # Update return authorization
        spree_put :update, order_id: order.number,
                           id: return_authorization.id,
                           return_authorization: { amount: "10.2", reason: "half broken" }

        expect(response).to redirect_to spree.admin_order_return_authorizations_url(order.number)
        return_authorization.reload
        expect(return_authorization.amount.to_s).to eq "10.2"
        expect(return_authorization.reason.to_s).to eq "half broken"
      end
    end
  end
end
