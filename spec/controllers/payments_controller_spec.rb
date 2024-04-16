# frozen_string_literal: true

require 'spec_helper'

describe PaymentsController, type: :controller do
  let!(:user) { create(:user) }
  let!(:order) { create(:order, user:) }
  let!(:payment) { create(:payment, order:) }

  describe "testing redirect_to_authorize" do
    context "when user isn't logged in" do
      it "redirects to the login page and set error flash msg" do
        get :redirect_to_authorize, params: { id: payment.id }
        expect(response).to redirect_to(root_path(anchor: "/login",
                                                  after_login: request.original_fullpath))
        expect(flash[:error]).to eq I18n.t("spree.orders.edit.login_to_view_order")
      end
    end

    context "when user is logged in" do
      before do
        allow(controller).to receive(:spree_current_user).and_return(user)
      end

      context "has cvv response message" do
        before do
          allow_any_instance_of(Spree::Payment).to receive(:cvv_response_message).and_return('http://example.com')
        end

        it "redirects to the CVV response URL" do
          get :redirect_to_authorize, params: { id: payment.id }
          expect(response).to redirect_to('http://example.com')
        end
      end

      context "doesn't have cvv response message" do
        it "redirect to order URL" do
          get :redirect_to_authorize, params: { id: payment.id }
          expect(response).to redirect_to(order_url(order))
        end
      end
    end
  end
end
