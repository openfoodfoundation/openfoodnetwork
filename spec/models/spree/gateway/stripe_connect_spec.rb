require 'spec_helper'

describe Spree::Gateway::StripeConnect, type: :model do
  let(:provider) do
    double('provider').tap do |p|
      p.stub(:purchase)
      p.stub(:authorize)
      p.stub(:capture)
    end
  end

  before do
    Stripe.api_key = "sk_test_123456"
    subject.stub(:options_for_purchase_or_auth).and_return(['money', 'cc', 'opts'])
    subject.stub(:provider).and_return provider
  end

  describe "#token_from_card_profile_ids" do
    let(:creditcard) { double(:creditcard) }
    context "when the credit card provided has a gateway_payment_profile_id" do
      before do
        allow(creditcard).to receive(:gateway_payment_profile_id) { "token_or_card_id123" }
        allow(subject).to receive(:tokenize_instance_customer_card) { "tokenized" }
      end

      context "when the credit card provided has a gateway_customer_profile_id" do
        before { allow(creditcard).to receive(:gateway_customer_profile_id) { "customer_id123" } }

        it "requests a new token via tokenize_instance_customer_card" do
          result = subject.send(:token_from_card_profile_ids, creditcard)
          expect(result).to eq "tokenized"
        end
      end

      context "when the credit card provided does not have a gateway_customer_profile_id" do
        before { allow(creditcard).to receive(:gateway_customer_profile_id) { nil } }
        it "returns the gateway_payment_profile_id (assumed to be a token already)" do
          result = subject.send(:token_from_card_profile_ids, creditcard)
          expect(result).to eq "token_or_card_id123"
        end
      end
    end

    context "when the credit card provided does not have a gateway_payment_profile_id" do
      before { allow(creditcard).to receive(:gateway_payment_profile_id) { nil } }
      before { allow(creditcard).to receive(:gateway_customer_profile_id) { "customer_id123" } }

      it "returns nil....?" do
        result = subject.send(:token_from_card_profile_ids, creditcard)
        expect(result).to be nil
      end
    end
  end

  describe "#tokenize_instance_customer_card" do
    let(:customer_id) { "customer123" }
    let(:card_id) { "card123" }
    let(:token_mock) { { id: "test_token123" } }

    before do
      stub_request(:post, "https://api.stripe.com/v1/tokens")
        .with(body: { "card" => "card123", "customer" => "customer123"})
        .to_return(body: JSON.generate(token_mock))
    end

    it "requests a new token for the customer and card from Stripe, and returns the id of the response" do
      expect(subject.send(:tokenize_instance_customer_card, customer_id, card_id)).to eq token_mock[:id]
    end
  end
end
