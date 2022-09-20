# frozen_string_literal: true

require 'spec_helper'
require 'stripe'

describe "checking out an order with a Stripe SCA payment method", type: :request do
  include ShopWorkflow
  include AuthenticationHelper
  include OpenFoodNetwork::ApiHelper
  include StripeHelper
  include StripeStubs

  context "when the user submits a new card and requests that the card is saved for later" do
    context "sends a request to stripe API", :vcr do
      let(:secret) { ENV['STRIPE_SECRET_TEST_API_KEY'] }

      before do
        Stripe.api_key = secret
      end

      it "makes a payment" do
        response = Stripe::Charge.create({
                                           amount: 2000,
                                           currency: 'usd',
                                           source: 'tok_visa', # obtained with Stripe.js
                                           metadata: { order_id: '6735' },
                                         })
      end

      it "creates a payment intent" do
        intent = Stripe::PaymentIntent.create({
                                                amount: 1099,
                                                currency: 'usd',
                                                payment_method_types: ['card'],
                                                metadata: {
                                                  order_id: '6735',
                                                },
                                              })
      end
    end
  end
end
