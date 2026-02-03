# frozen_string_literal: true

RSpec.describe Spree::Gateway::StripeSCA, :vcr, :stripe_version do
  let(:order) { create(:order_ready_for_payment) }

  let(:year_valid) { Time.zone.now.year.next }

  let(:credit_card) { create(:credit_card, gateway_payment_profile_id: pm_card.id) }

  let(:payment) {
    create(
      :payment,
      order:,
      amount: order.total,
      payment_method: subject,
      source: credit_card,
      response_code: payment_intent.id
    )
  }

  let(:gateway_options) {
    { order_id: order.number }
  }

  # Stripe testing card:
  #     https://stripe.com/docs/testing?testing-method=payment-methods
  let(:pm_card) { Stripe::PaymentMethod.retrieve('pm_card_mastercard') }

  let(:payment_intent) do
    Stripe::PaymentIntent.create({
                                   amount: 1000, # given in AUD cents
                                   currency: 'aud', # AUD to match order currency
                                   payment_method: pm_card,
                                   payment_method_types: ['card'],
                                   capture_method: 'manual',
                                 })
  end

  let(:connected_account) do
    Stripe::Account.create({
                             type: 'standard',
                             country: 'AU',
                             email: 'carrot.producer@example.com'
                           })
  end

  after do
    Stripe::Account.delete(connected_account.id)
  end

  describe "#purchase" do
    # Stripe acepts amounts as positive integers representing how much to charge
    # in the smallest currency unit
    let(:capture_amount) { order.total.to_i * 100 } # order total is 10 AUD

    before do
      # confirms the payment
      Stripe::PaymentIntent.confirm(payment_intent.id)
    end

    it "completes the purchase" do
      payment

      response = subject.purchase(capture_amount, credit_card, gateway_options)
      expect(response.success?).to eq true
    end

    it "provides an error message to help developer debug" do
      response_error = subject.purchase(capture_amount, credit_card, gateway_options)

      expect(response_error.success?).to eq false
      expect(response_error.message).to eq "No pending payments"
    end
  end

  describe "#void" do
    let(:stripe_test_account) { connected_account.id }

    before do
      # Inject our test stripe account
      stripe_account = create(:stripe_account, stripe_user_id: stripe_test_account)
      allow(StripeAccount).to receive(:find_by).and_return(stripe_account)

      create(
        :payment,
        order:,
        amount: order.total,
        payment_method: subject,
        source: credit_card,
        response_code: payment_intent.id
      )
    end

    context "with a confirmed payment" do
      # Link the payment intent to our test stripe account, and automatically confirm and capture
      # the payment.
      let(:payment_intent) do
        Stripe::PaymentIntent.create(
          {
            amount: 1000, # given in AUD cents
            currency: 'aud', # AUD to match order currency
            payment_method: 'pm_card_mastercard',
            payment_method_types: ['card'],
            capture_method: 'automatic',
            confirm: true,
          },
          stripe_account: stripe_test_account
        )
      end

      it "refunds the payment" do
        response = subject.void(payment_intent.id, {})

        expect(response.success?).to eq true
      end
    end

    context "with a voidable payment" do
      # Link the payment intent to our test stripe account
      let(:payment_intent) do
        Stripe::PaymentIntent.create(
          {
            amount: 1000, # given in AUD cents
            currency: 'aud', # AUD to match order currency
            payment_method: 'pm_card_mastercard',
            payment_method_types: ['card'],
            capture_method: 'manual'
          },
          stripe_account: stripe_test_account
        )
      end

      it "void the payment" do
        response = subject.void(payment_intent.id, {})

        expect(response.success?).to eq true
      end
    end
  end

  describe "#credit" do
    let(:stripe_test_account) { connected_account.id }

    before do
      # Inject our test stripe account
      stripe_account = create(:stripe_account, stripe_user_id: stripe_test_account)
      allow(StripeAccount).to receive(:find_by).and_return(stripe_account)
    end

    it "refunds the payment" do
      # Link the payment intent to our test stripe account, and automatically confirm and capture
      # the payment.
      payment_intent = Stripe::PaymentIntent.create(
        {
          amount: 1000, # given in AUD cents
          currency: 'aud', # AUD to match order currency
          payment_method: 'pm_card_mastercard',
          payment_method_types: ['card'],
          capture_method: 'automatic',
          confirm: true,
        },
        stripe_account: stripe_test_account
      )

      response = subject.credit(1000, nil, payment_intent.id, {})

      expect(response.success?).to eq true
    end
  end

  describe "#error message" do
    context "when payment intent state is not in 'requires_capture' state" do
      before do
        payment
      end

      it "does not succeed if payment intent state is not requires_capture" do
        response = subject.purchase(order.total, credit_card, gateway_options)
        expect(response.success?).to eq false
        expect(response.message).to eq "Invalid payment state: requires_confirmation"
      end
    end
  end

  describe "#external_payment_url" do
    let(:redirect_double) { instance_double(Checkout::StripeRedirect) }

    it "returns nil when an order is not supplied" do
      expect(subject.external_payment_url({})).to eq nil
    end

    it "calls Checkout::StripeRedirect" do
      expect(Checkout::StripeRedirect).to receive(:new).with(subject, order) { redirect_double }
      expect(redirect_double).to receive(:path).and_return("http://stripe-test.org")

      expect(subject.external_payment_url(order:)).to eq "http://stripe-test.org"
    end
  end
end
