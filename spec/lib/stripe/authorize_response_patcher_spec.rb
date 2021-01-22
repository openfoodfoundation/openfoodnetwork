# frozen_string_literal: true

require 'spec_helper'

module Stripe
  describe AuthorizeResponsePatcher do
    describe "#call!" do
      let(:patcher) { Stripe::AuthorizeResponsePatcher.new(response) }
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
          { "status" => "requires_source_action",
            "next_source_action" => { "type" => "authorize_with_url",
                                      "authorize_with_url" => { "url" => "https://www.stripe.com/authorize" } } }
        }

        it "patches response.cvv_result.message with the url in the response" do
          new_response = patcher.call!
          expect(new_response.cvv_result['message']).to eq "https://www.stripe.com/authorize"
        end
      end
    end
  end
end
