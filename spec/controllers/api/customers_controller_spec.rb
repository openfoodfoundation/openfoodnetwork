require 'spec_helper'

module Api
  describe CustomersController, type: :controller do
    include AuthenticationWorkflow
    render_views

    let(:user) { create(:user) }
    let(:customer) { create(:customer, user: user) }
    let(:params) { { format: :json, id: customer.id, customer: { code: '123' } } }

    describe "#update" do
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
            expect(response.body).to eq customer.id.to_s
          end
        end

        context "when the update request fails" do
          before { params[:customer][:email] = '' }

          it "returns a 422, with an error message" do
            spree_post :update, params
            expect(response.status).to be 422
            expect(JSON.parse(response.body)['error']).to be
          end
        end
      end
    end
  end
end
