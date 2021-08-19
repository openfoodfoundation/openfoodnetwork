# frozen_string_literal: true

require 'spec_helper'
require 'stripe/credit_card_clone_finder'

module Stripe
  describe CreditCardCloneFinder do
    describe "#find_cloned_card", vcr: true do
      context "a card with no gateway_payment_profile_id" do
        let(:card) { double(:card, { gateway_payment_profile_id: nil }) }
        let(:stripe_account) { ENV["STRIPE_ACCOUNT_ID"] }

        it "should return nil" do
          finder = Stripe::CreditCardCloneFinder.new(card, stripe_account)
          expect(finder.find_cloned_card).to be(nil)
        end
      end

      context "a card without a clone" do
        let(:card) { create(:stored_credit_card) }
        let(:stripe_account) { ENV["STRIPE_ACCOUNT_ID"] }

        before do
          allow(card).to receive_message_chain(:user, :email) { "ofn@example.com" }
        end

        it "should return nil" do
          Stripe.api_key = ENV["STRIPE_SECRET_KEY"]
          VCR.use_cassette("clone_finder") do
            finder = Stripe::CreditCardCloneFinder.new(card, stripe_account)
            expect(finder.find_cloned_card).to eq(nil)
          end
        end
      end
    end
  end
end
