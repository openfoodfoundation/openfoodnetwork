# frozen_string_literal: true

require 'spec_helper'

describe PaymentsController, type: :controller do
    let!(:user) { create(:user) }
    let!(:order) { create(:order, user: user) }
    let!(:payment) { create(:payment, order: order) }
    
    describe "testing redirect_to_authorize" do
        context "when user isn't logged in" do
            it "redirects to the login page and set error flash msg" do
                get :redirect_to_authorize, params: { id: payment.id }
                expect(response).to redirect_to(root_path(anchor: "/login", after_login: request.original_fullpath))
                expect(flash[:error]).to eq I18n.t("spree.orders.edit.login_to_view_order")
            end
        end
    
        context "when user is logged in" do
        
        end
    end
end