require 'spec_helper'
require 'support/request/authentication_workflow'

describe Spree::CreditCardsController do
  include AuthenticationWorkflow
  let(:user) { create_enterprise_user }
  let(:token) { "tok_234bd2c22" }
  let(:params) do
    {
      format: :json,
      "exp_month" => 12,
      "exp_year" => 2020,
      "last4" => 4242,
      "token" => token,
      "cc_type" => "visa"
    }
  end

  before do
    Stripe.api_key = "sk_test_12345"
    controller.stub(:spree_current_user) { user }
    stub_request(:post, "https://api.stripe.com/v1/customers")
      .with(:body => { email: user.email, source: token })
      .to_return(response_mock)
  end

  describe "#new_from_token" do
    context "when the request to store the customer/card with Stripe is successful" do
      let(:response_mock) { { status: 200, body: JSON.generate({ id: "cus_AZNMJ", default_source: "card_1AEEb" }) } }

      it "saves the card locally" do
        expect{ post :new_from_token, params }.to change(Spree::CreditCard, :count).by(1)

        card = Spree::CreditCard.last
        card.gateway_payment_profile_id.should eq "card_1AEEb"
        card.gateway_customer_profile_id.should eq "cus_AZNMJ"
        card.user_id.should eq user.id
        card.last_digits.should eq "4242"
      end

      context "when saving the card locally fails" do
        before do
          allow(controller).to receive(:stored_card_attributes) { {} }
        end

        it "renders a flash error" do
          expect{ post :new_from_token, params }.to_not change(Spree::CreditCard, :count)

          json_response = JSON.parse(response.body)
          flash_message = I18n.t(:spree_gateway_error_flash_for_checkout, error: I18n.t(:card_could_not_be_saved))
          expect(json_response["flash"]["error"]).to eq flash_message
        end
      end
    end

    context "when the request to store the customer/card with Stripe fails" do
      let(:response_mock) { { status: 402, body: JSON.generate({ error: { message: "Bup-bow..." }}) } }
      it "doesn't save the card locally, and renders a flash error" do
        expect{ post :new_from_token, params }.to_not change(Spree::CreditCard, :count)

        json_response = JSON.parse(response.body)
        flash_message = I18n.t(:spree_gateway_error_flash_for_checkout, error: "Bup-bow...")
        expect(json_response["flash"]["error"]).to eq flash_message
      end
    end
  end
end
