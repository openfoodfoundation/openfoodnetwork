# frozen_string_literal: true

RSpec.describe Stripe::AuthorizeResponsePatcher do
  describe "#call!" do
    subject(:patcher) { Stripe::AuthorizeResponsePatcher.new(response) }
    let(:params) { {} }
    let(:response) { ActiveMerchant::Billing::Response.new(true, "Transaction approved", params) }

    context "when url not found in response" do
      it "does nothing" do
        new_response = patcher.call!
        expect(new_response).to eq response
      end
    end

    context "when url is found in response" do
      let(:params) {
        {
          "status" => "requires_source_action",
          "next_source_action" => {
            "type" => "authorize_with_url",
            "authorize_with_url" => { "url" => "https://www.stripe.com/authorize" }
          }
        }
      }

      it "patches response.cvv_result.redirect_auth_url with the url in the response" do
        new_response = patcher.call!
        expect(new_response.cvv_result['redirect_auth_url']).to eq "https://www.stripe.com/authorize"
      end

      context "with invalid url containing 'stripe.com'" do
        let(:params) {
          {
            "status" => "requires_source_action",
            "next_source_action" => {
              "type" => "authorize_with_url",
              "authorize_with_url" => { "url" => "https://www.evil-stripe.com.malicious.org/authorize" }
            }
          }
        }

        it "patches response.cvv_result.redirect_auth_url with nil" do
          new_response = patcher.call!
          expect(new_response.cvv_result['redirect_auth_url']).to eq nil
        end
      end
    end
  end
end
