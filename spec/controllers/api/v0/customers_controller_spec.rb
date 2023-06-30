# frozen_string_literal: true

require 'spec_helper'

module Api
  describe V0::CustomersController, type: :controller do
    include AuthenticationHelper
    render_views

    let(:user) { create(:user) }

    describe "index" do
      let!(:customer1) { create(:customer, created_manually: true) }
      let!(:customer2) { create(:customer, created_manually: true) }

      before do
        user.customers << customer1
        allow(controller).to receive(:spree_current_user) { user }
      end

      it "lists customers associated with the current user" do
        get :index
        expect(response.status).to eq 200
        expect(json_response.length).to eq 1
        expect(json_response.first[:id]).to eq customer1.id
      end
    end

    describe "#update" do
      let(:customer) { create(:customer, user: user) }
      let(:params) { { format: :json, id: customer.id, customer: { code: '123' } } }

      context "as a user who is not associated with the customer" do
        before do
          allow(controller).to receive(:spree_current_user) { create(:user) }
        end

        it "returns unauthorized" do
          spree_post :update, params
          assert_unauthorized!
        end
      end

      context "as the user associated with the customer" do
        before do
          allow(controller).to receive(:spree_current_user) { user }
        end

        context "when the update request is successful" do
          it "returns the id of the updated customer" do
            spree_post :update, params
            expect(response.status).to eq 200
            expect(json_response[:id]).to eq customer.id
          end
        end

        context "when the update request fails" do
          before { params[:customer][:email] = '' }

          it "returns a 422, with an error message" do
            spree_post :update, params
            expect(response.status).to be 422
            expect(json_response[:error]).to be
          end
        end
      end
    end
  end
end
