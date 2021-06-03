# frozen_string_literal: true

require 'spec_helper'

describe Spree::Gateway::StripeConnect, type: :model do
  let(:provider) do
    instance_double(ActiveMerchant::Billing::StripeGateway).tap do |p|
      allow(p).to receive(:purchase)
      allow(p).to receive(:authorize)
      allow(p).to receive(:capture)
      allow(p).to receive(:refund)
    end
  end

  let(:stripe_account_id) { "acct_123" }

  before do
    Stripe.api_key = "sk_test_123456"
    allow(subject).to receive(:stripe_account_id) { stripe_account_id }
    allow(subject).to receive(:options_for_purchase_or_auth).and_return(['money', 'cc', 'opts'])
    allow(subject).to receive(:provider).and_return provider
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
        .with(body: { "card" => "card123", "customer" => "customer123" })
        .to_return(body: JSON.generate(token_mock))
    end

    it "requests a new token for the customer and card from Stripe, and returns the id of the response" do
      expect(subject.send(:tokenize_instance_customer_card, customer_id, card_id)).to eq token_mock[:id]
    end
  end

  describe "#credit" do
    let(:gateway_options) { { some: 'option' } }
    let(:money) { double(:money) }
    let(:response_code) { double(:response_code) }

    before do
      subject.credit(money, double(:creditcard), response_code, gateway_options)
    end

    it "delegates to ActiveMerchant::Billing::StripeGateway#refund" do
      expect(provider).to have_received(:refund)
    end

    it "adds the stripe_account to the gateway options hash" do
      expect(provider).to have_received(:refund).with(money, response_code, hash_including(stripe_account: stripe_account_id))
    end
  end

  describe "#charging offline" do
    let(:gateway_options) { { some: 'option' } }
    let(:money) { double(:money) }
    let(:card) { double(:creditcard) }

    it "uses #purchase to charge offline" do
      subject.charge_offline(money, card, gateway_options)
      expect(provider).to have_received(:purchase).with('money', 'cc', 'opts')
    end
  end
end
