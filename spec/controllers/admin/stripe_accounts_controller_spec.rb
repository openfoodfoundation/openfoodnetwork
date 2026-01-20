# frozen_string_literal: true

RSpec.describe Admin::StripeAccountsController do
  let(:enterprise) { create(:distributor_enterprise) }

  describe "#connect" do
    let(:client_id) { ENV.fetch('STRIPE_CLIENT_ID', nil) }

    before do
      Stripe.client_id = client_id
      allow(controller).to receive(:spree_current_user) { enterprise.owner }
    end

    it "redirects to Stripe Authorization url constructed OAuth" do
      # A deterministic id results in a deterministic state JWT token
      get :connect, params: { enterprise_id: 1 }

      expect(response).to redirect_to("https://connect.stripe.com/oauth/authorize?" \
                                      "state=eyJhbGciOiJIUzI1NiJ9.eyJlbnRlcnByaXNlX2lkIjoiMSJ9" \
                                      ".jSSFGn0bLhwuiQYK5ORmHWW7aay1l030bcfGwn1JbFg&" \
                                      "scope=read_write&client_id=#{client_id}&response_type=code")
    end
  end

  describe "#destroy" do
    let(:params) { { format: :json, id: "client_id" } }

    context "when the specified stripe account doesn't exist" do
      it "raises an error?" do
        spree_delete :destroy, params
      end
    end

    context "when the specified stripe account exists", :vcr, :stripe_version do
      let(:connected_account) do
        Stripe::Account.create({
                                 type: 'standard',
                                 country: 'AU',
                                 email: 'jumping.jack@example.com',
                                 business_type: "non_profit"
                               })
      end
      let(:stripe_account) {
        create(:stripe_account, enterprise:, stripe_user_id: connected_account.id)
      }

      before do
        # So that we can stub #deauthorize_and_destroy
        allow(StripeAccount).to receive(:find) { stripe_account }
        params[:id] = stripe_account.id
      end

      after do
        Stripe::Account.delete(connected_account.id)
      end

      context "when I don't manage the enterprise linked to the stripe account" do
        let(:some_user) { create(:user) }

        before { allow(controller).to receive(:spree_current_user) { some_user } }

        it "redirects to unauthorized" do
          spree_delete :destroy, params
          expect(response).to redirect_to unauthorized_path
        end
      end

      context "when I manage the enterprise linked to the stripe account" do
        before { allow(controller).to receive(:spree_current_user) { enterprise.owner } }

        context "and the attempt to deauthorize_and_destroy succeeds" do
          before { allow(stripe_account).to receive(:deauthorize_and_destroy) { stripe_account } }

          it "redirects to unauthorized" do
            spree_delete :destroy, params
            expect(response).to redirect_to edit_admin_enterprise_path(enterprise)
            expect(flash[:success]).to eq "Stripe account disconnected."
          end
        end

        context "and the attempt to deauthorize_and_destroy fails" do
          before { allow(stripe_account).to receive(:deauthorize_and_destroy) { false } }

          it "redirects to unauthorized" do
            spree_delete :destroy, params
            expect(response).to redirect_to edit_admin_enterprise_path(enterprise)
            expect(flash[:error]).to eq "Failed to disconnect Stripe."
          end
        end
      end
    end
  end

  describe "#status" do
    let(:params) { { format: :json, enterprise_id: enterprise.id } }

    context "when I don't manage the specified enterprise" do
      let(:user) { create(:user) }

      before do
        allow(controller).to receive(:spree_current_user) { user }
      end

      it "redirects to unauthorized" do
        get(:status, params:)
        expect(response).to redirect_to unauthorized_path
      end
    end

    context "when I manage the specified enterprise" do
      before do
        allow(controller).to receive(:spree_current_user) { enterprise.owner }
      end

      context "when Stripe is not enabled" do
        it "returns with a status of 'stripe_disabled'" do
          get(:status, params:)
          json_response = response.parsed_body
          expect(json_response["status"]).to eq "stripe_disabled"
        end
      end

      context "when Stripe is enabled" do
        before { allow(Spree::Config).to receive(:stripe_connect_enabled).and_return(true) }

        context "when no stripe account is associated with the specified enterprise" do
          it "returns with a status of 'account_missing'" do
            get(:status, params:)
            json_response = response.parsed_body
            expect(json_response["status"]).to eq "account_missing"
          end
        end

        context "when a stripe account is associated with the specified enterprise", :vcr,
                :stripe_version do
          let(:connected_account) do
            Stripe::Account.create({
                                     type: 'standard',
                                     country: 'AU',
                                     email: 'jumping.jack@example.com',
                                     business_type: "non_profit"
                                   })
          end
          let!(:account) {
            create(:stripe_account, stripe_user_id: connected_account.id, enterprise:)
          }

          after do
            Stripe::Account.delete(connected_account.id)
          end

          context "but access has been revoked or does not exist on stripe's servers" do
            let(:message) {
              "The provided key 'sk_test_******************************uCJm' " \
                "does not have access to account 'acct_fake_account' (or that account " \
                "does not exist). Application access may have been revoked."
            }
            before do
              account.update(stripe_user_id: "acct_fake_account")
            end

            it "returns with a status of 'access_revoked'" do
              expect {
                response = get(:status, params:)
              }.to raise_error Stripe::PermissionError, message
            end
          end

          context "which is connected" do
            it "returns with a status of 'connected'" do
              response = get(:status, params:)
              json_response = response.parsed_body
              expect(json_response["status"]).to eq "connected"
              # serializes required attrs
              expect(json_response["charges_enabled"]).to eq false
              # ignores other attrs
              expect(json_response["some_other_attr"]).to be nil
            end
          end
        end
      end
    end
  end
end
