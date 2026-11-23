# frozen_string_literal: true

RSpec.describe Spree::Gateway::PayPalRest do
  subject(:gateway) { create(:paypal_rest_payment_method) }

  describe "preference validation" do
    it "accepts the supported solution and server values" do
      expect(gateway).to be_valid
    end

    it "rejects an unsupported solution" do
      gateway.preferred_solution = 'Sole (typo)'

      expect(gateway).not_to be_valid
      expect(gateway.errors[:preferred_solution]).to be_present
    end

    it "rejects an unsupported server" do
      gateway.preferred_server = 'Live'

      expect(gateway).not_to be_valid
      expect(gateway.errors[:preferred_server]).to be_present
    end

    it "hides test_mode and keeps a stable field order" do
      expect(gateway.preferences.keys).to eq(%i[client_id client_secret solution server])
    end
  end

  describe "#provider_class" do
    it "uses the PayPal REST provider" do
      expect(gateway.provider_class).to eq(PaypalRest::Provider)
    end
  end

  describe "#provider" do
    it "builds a provider from the configured preferences" do
      expect(PaypalRest::Provider).to receive(:new).with(
        hash_including(
          client_id: 'test-client-id',
          client_secret: 'test-client-secret',
          server: 'sandbox'
        )
      )

      gateway.provider
    end
  end

  describe "configuration" do
    it "uses the paypal_rest method type and source model" do
      expect(gateway.method_type).to eq('paypal_rest')
      expect(gateway.payment_source_class).to eq(Spree::PaypalRestCheckout)
    end

    it "redirects to the external gateway" do
      expect(gateway).to be_external_gateway
      expect(gateway.external_payment_url({})).to include('/paypal/rest/create')
    end

    it "does not offer immediate-capture actions" do
      expect(gateway.actions).to be_empty
    end
  end
end
