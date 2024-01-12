# frozen_string_literal: true

require 'spec_helper'
require 'stripe/credit_card_cloner'

module Stripe
  describe CreditCardCloner do
    describe "#find_or_clone" do
      include StripeStubs

      let(:credit_card) { create(:credit_card, user: create(:user)) }
      let(:stripe_account_id) { "abc123" }

      let(:cloner) { Stripe::CreditCardCloner.new(credit_card, stripe_account_id) }

      let(:customer_id) { "cus_A123" }
      let(:payment_method_id) { "pm_1234" }
      let(:new_customer_id) { "cus_A456" }
      let(:new_payment_method_id) { "pm_456" }
      let(:payment_method_response_mock) { { status: 200, body: payment_method_response_body } }

      let(:payment_method_response_body) {
        JSON.generate(id: new_payment_method_id)
      }

      let(:secret) { ENV.fetch('STRIPE_SECRET_TEST_API_KEY', nil) }


      let(:cardholder) { 
        Stripe::Issuing::Cardholder.create({
          name: 'Damian Michelfelder',
          email: 'damian.michelfelder@example.de',
          phone_number: '+49 30 12345-67',
          status: 'active',
          type: 'individual',
          individual: {
            first_name: 'Damian',
            last_name: 'Michelfelder',
            dob: {day: 1, month: 11, year: 1981},
          },
          billing: {
            address: {
              line1: "20 Waldweg",
              city: "Berlin",
              postal_code: "45276",
              country: "DE",
            },
          },
        })
      }

      before do
        Stripe.api_key = secret

        stub_customers_post_request email: credit_card.user.email,
                                    response: { customer_id: new_customer_id },
                                    stripe_account_header: true

        # def stub_customers_post_request(email:, response: {}, stripe_account_header: false)
        #   stub = stub_request(:post, "https://api.stripe.com/v1/customers")
        #     .with(body: { email: })
        #   stub = stub.with(headers: { 'Stripe-Account' => 'abc123' }) if stripe_account_header
        #   stub.to_return(customers_response_mock(response))
        # end

        stub_retrieve_payment_method_request(payment_method_id)
        
        # def stub_retrieve_payment_method_request(payment_method_id = "pm_1234")
        #   stub_request(:get, "https://api.stripe.com/v1/payment_methods/#{payment_method_id}")
        #     .to_return(retrieve_payment_method_response_mock({}))
        # end

        stub_list_customers_request(email: credit_card.user.email, response: {})
        
        #  def stub_list_customers_request(email:, response: {})
        #    stub = stub_request(:get, "https://api.stripe.com/v1/customers?email=#{email}&limit=100")
        #    stub = stub.with(
        #      headers: { 'Stripe-Account' => 'abc123' }
        #    )
        #    stub.to_return(list_customers_response_mock(response))
        #  end
        
        stub_get_customer_payment_methods_request(customer: "cus_A456", response: {})

        # def stub_get_customer_payment_methods_request(customer: "cus_A456", response: {})
        #   stub = stub_request(
        #     :get, "https://api.stripe.com/v1/payment_methods?customer=#{customer}&limit=100&type=card"
        #   )
        #   stub = stub.with(
        #     headers: { 'Stripe-Account' => 'abc123' }
        #   )
        #   stub.to_return(get_customer_payment_methods_response_mock(response))
        # end
        
        stub_add_metadata_request(payment_method: "pm_456", response: {})

        # def stub_add_metadata_request(payment_method: "pm_456", response: {})
        #   stub = stub_request(:post, "https://api.stripe.com/v1/payment_methods/#{payment_method}")
        #   stub = stub.with(body: { metadata: { 'ofn-clone': true } })
        #   stub = stub.with(
        #     headers: { 'Stripe-Account' => 'abc123' }
        #   )
        #   stub.to_return(add_metadata_response_mock(response))
        # end

        stub_request(:post,
                     "https://api.stripe.com/v1/payment_methods/#{new_payment_method_id}/attach")
          .with(body: { customer: new_customer_id },
                headers: { 'Stripe-Account' => stripe_account_id })
          .to_return(payment_method_response_mock)

        credit_card.update_attribute :gateway_payment_profile_id, payment_method_id
      end

      context "when called with a card without a customer (one time usage card)" do
        before do
          stub_request(:post, "https://api.stripe.com/v1/payment_methods")
            .with(body: { payment_method: payment_method_id },
                  headers: { 'Stripe-Account' => stripe_account_id })
            .to_return(payment_method_response_mock)
        end

        it "clones the payment method only" do
          customer_id, payment_method_id = cloner.find_or_clone

          expect(payment_method_id).to eq new_payment_method_id
          expect(customer_id).to eq nil
        end
      end

      context "when called with a valid customer and payment_method" do
        before do
          stub_request(:post, "https://api.stripe.com/v1/payment_methods")
            .with(body: { customer: customer_id, payment_method: payment_method_id },
                  headers: { 'Stripe-Account' => stripe_account_id })
            .to_return(payment_method_response_mock)

          credit_card.update_attribute :gateway_customer_profile_id, customer_id
        end

        it "clones both the payment method and the customer" do
          customer_id, payment_method_id = cloner.find_or_clone

          expect(payment_method_id).to eq new_payment_method_id
          expect(customer_id).to eq new_customer_id
        end
      end
    end
  end
end
