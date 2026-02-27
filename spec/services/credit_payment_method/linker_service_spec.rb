# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CreditPaymentMethod::LinkerService do
  let(:enterprise) { create(:distributor_enterprise) }

  around do |example|
    # after_save call back will call the linker we are testing, we disable it to avoid
    # unintended side effect
    Enterprise.skip_callback(:save, :after, :add_credit_payment_method)
    example.run
    Enterprise.set_callback(:save, :after, :add_credit_payment_method)
  end

  describe ".link" do
    it "links the given enterprise to customer credit related payment method" do
      api_payment_method = create(
        :payment_method,
        name: Rails.application.config.api_payment_method[:name],
        internal: true
      )
      credit_payment_method = create(:customer_credit_payment_method)

      described_class.link(enterprise:)

      expect(enterprise.payment_methods.unscoped).to include(api_payment_method)
      expect(enterprise.payment_methods.unscoped).to include(credit_payment_method)
    end

    context "when payment method don't exist" do
      it "creates customer credit related payment method" do
        described_class.link(enterprise:)

        api_payment_method = Spree::PaymentMethod.internal.find_by(
          name: Rails.application.config.api_payment_method[:name]
        )
        expect(api_payment_method).not_to be_nil
        expect(api_payment_method.description).to eq(
          Rails.application.config.api_payment_method[:description]
        )
        expect(api_payment_method.display_name).to eq("API customer credit")
        expect(api_payment_method.display_description).to eq(
          "Used to credit customer via customer account transactions endpoint"
        )
        expect(api_payment_method.display_on).to eq("back_end")

        credit_payment_method = Spree::PaymentMethod.customer_credit
        expect(credit_payment_method).not_to be_nil
        expect(credit_payment_method.description).to eq(
          Rails.application.config.credit_payment_method[:description]
        )
        expect(credit_payment_method.display_name).to eq("Customer credit")
        expect(credit_payment_method.display_description).to eq("Allow customer to pay with credit")
        expect(credit_payment_method.display_on).to eq("both")
      end
    end
  end
end
