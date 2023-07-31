# frozen_string_literal: true

require 'spec_helper'

class Spree::Gateway::Test < Spree::Gateway
end

describe Spree::PaymentMethod do
  describe ".managed_by scope" do
    subject! { create(:payment_method) }
    let(:owner) { subject.distributors.first.owner }
    let(:other_user) { create(:user) }
    let(:admin) { create(:admin_user) }

    it "returns everything for admins" do
      expect(Spree::PaymentMethod.managed_by(admin)).to eq [subject]
    end

    it "returns payment methods of managed enterprises" do
      expect(Spree::PaymentMethod.managed_by(owner)).to eq [subject]
    end

    it "returns nothing for other users" do
      expect(Spree::PaymentMethod.managed_by(other_user)).to eq []
    end
  end

  describe "#available" do
    let(:enterprise) { create(:enterprise) }

    before do
      Spree::PaymentMethod.delete_all

      [nil, 'both', 'back_end'].each do |display_on|
        Spree::Gateway::Test.create(
          name: 'Display Both',
          display_on: display_on,
          active: true,
          environment: 'test',
          description: 'foofah',
          distributors: [enterprise]
        )
      end
      expect(Spree::PaymentMethod.all.size).to eq 3
    end

    it "should return all methods available to front-end/back-end when no parameter is passed" do
      expect(Spree::PaymentMethod.available.size).to eq 2
    end

    it "should return all methods available to front-end/back-end when display_on = :both" do
      expect(Spree::PaymentMethod.available(:both).size).to eq 2
    end

    it "should return all methods available to back-end when display_on = :back_end" do
      expect(Spree::PaymentMethod.available(:back_end).size).to eq 2
    end
  end

  describe "#configured?" do
    context "non-Stripe payment method" do
      let(:payment_method) { build(:payment_method) }

      it "returns true" do
        expect(payment_method).to be_configured
      end
    end

    context "Stripe payment method" do
      let(:payment_method) { create(:stripe_sca_payment_method) }

      before do
        allow(Spree::Config).to receive(:stripe_connect_enabled).and_return(true)
        allow(Stripe).to receive(:publishable_key) { "some_key" }
      end

      context "and Stripe Connect is enabled and a Stripe publishable key, account id, account
               owner are all present" do
        it "returns true" do
          expect(payment_method).to be_configured
        end
      end

      context "and Stripe Connect is disabled" do
        before { allow(Spree::Config).to receive(:stripe_connect_enabled).and_return(false) }

        it "returns false" do
          expect(payment_method).not_to be_configured
        end
      end

      context "and a Stripe publishable key is not present" do
        before { allow(Stripe).to receive(:publishable_key) { nil } }

        it "returns false" do
          expect(payment_method).not_to be_configured
        end
      end

      context "and a Stripe account owner is not present" do
        before { payment_method.preferred_enterprise_id = nil }

        it "returns false" do
          expect(payment_method).not_to be_configured
        end
      end

      context "and a Stripe account ID is not present" do
        before do
          StripeAccount.find_by(
            enterprise_id: payment_method.preferred_enterprise_id
          ).update_column(:stripe_user_id, nil)
        end

        it "returns false" do
          expect(payment_method).not_to be_configured
        end
      end
    end
  end

  it "orders payment methods by name" do
    pm1 = create(:payment_method, name: 'ZZ')
    pm2 = create(:payment_method, name: 'AA')
    pm3 = create(:payment_method, name: 'BB')

    expect(Spree::PaymentMethod.by_name).to eq([pm2, pm3, pm1])
  end

  it "raises errors when required fields are missing" do
    pm = Spree::PaymentMethod.new
    pm.save
    expect(pm.errors.to_a).to eq(["Name can't be blank", "At least one hub must be selected"])
  end

  it "generates a clean name for known Payment Method types" do
    expect(Spree::PaymentMethod::Check.clean_name)
      .to eq('Cash/EFT/etc. (payments for which automatic validation is not required)')
    expect(Spree::Gateway::PayPalExpress.clean_name).to eq('PayPal Express')
    expect(Spree::Gateway::StripeSCA.clean_name).to eq('Stripe SCA')
    expect(Spree::Gateway::BogusSimple.clean_name).to eq('BogusSimple')
    expect(Spree::Gateway::Bogus.clean_name).to eq('Bogus')
  end

  it "computes the amount of fees" do
    order = create(:order)

    free_payment_method = create(:payment_method) # flat rate calculator with preferred_amount of 0
    expect(free_payment_method.compute_amount(order)).to eq 0

    flat_rate_payment_method = create(:payment_method,
                                      calculator: ::Calculator::FlatRate.new(preferred_amount: 10))
    expect(flat_rate_payment_method.compute_amount(order)).to eq 10

    flat_percent_payment_method = create(:payment_method,
                                         calculator: ::Calculator::FlatPercentItemTotal
                                           .new(preferred_flat_percent: 10))
    expect(flat_percent_payment_method.compute_amount(order)).to eq 0

    product = create(:product)
    order.contents.add(product.variants.first)
    expect(flat_percent_payment_method.compute_amount(order)).to eq 2.0
  end

  describe "scope" do
    describe "filtering to specified distributors" do
      let!(:distributor_a) { create(:distributor_enterprise) }
      let!(:distributor_b) { create(:distributor_enterprise) }
      let!(:distributor_c) { create(:distributor_enterprise) }

      let!(:payment_method_a) {
        create(:payment_method, distributors: [distributor_a, distributor_b])
      }
      let!(:payment_method_b) { create(:payment_method, distributors: [distributor_b]) }
      let!(:payment_method_c) { create(:payment_method, distributors: [distributor_c]) }

      it "includes only unique records under specified distributors" do
        result = described_class.for_distributors([distributor_a, distributor_b])
        expect(result.length).to eq(2)
        expect(result).to include(payment_method_a)
        expect(result).to include(payment_method_b)
      end
    end
  end
end
