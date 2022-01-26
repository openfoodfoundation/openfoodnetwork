# frozen_string_literal: true

require 'spec_helper'
require_relative '../../db/migrate/20220118053107_convert_stripe_connect_to_stripe_sca'

module Spree
  class Gateway
    class StripeConnect < Gateway::StripeSCA
      # This class got deleted from the code base but this minimum definition
      # is enough for this test.
    end
  end
end

describe ConvertStripeConnectToStripeSca do
  let(:owner) { create(:distributor_enterprise) }
  let(:new_owner) { create(:distributor_enterprise) }
  let(:old_stripe_connect) {
    Spree::Gateway::StripeConnect.create!(
      name: "Stripe",
      environment: "test",
      preferred_enterprise_id: owner.id,
      distributor_ids: [owner.id]
    )
  }
  let(:result) { Spree::PaymentMethod.find(old_stripe_connect.id) }

  before do
    # Activate the cache because it's deactivated in test environment.
    allow(Spree::Preferences::Store.instance).to receive(:should_persist?).and_return(true)

    # Create the payment method after cache activation to store the owner.
    old_stripe_connect
  end

  it "converts payment methods" do
    subject.up

    expect(result.class).to eq Spree::Gateway::StripeSCA
  end

  it "keeps attributes" do
    subject.up

    expect(result.name).to eq "Stripe"
    expect(result.environment).to eq "test"
    expect(result.distributor_ids).to eq [owner.id]
  end

  it "keeps Spree preferences" do
    subject.up

    expect(result.preferred_enterprise_id).to eq owner.id
  end

  it "doesn't move outdated StripeConnect preferences to StripeSCA methods" do
    # When you change the type of a payment method in the admin screen
    # it leaves old entries in the spree_preferences table.
    # Here is a simulation of such a change:
    old_stripe_connect.update_columns(type: "Spree::Gateway::StripeSCA")
    changed_method = Spree::PaymentMethod.find(old_stripe_connect.id)
    changed_method.preferred_enterprise_id = new_owner.id

    subject.up

    expect(result.preferred_enterprise_id).to eq new_owner.id
  end

  it "keeps Spree preferences despite conflicting preference keys" do
    # We change the payment method to StripeSCA and then back to StripeConnect
    # to generate a conflicting preference. We want to keep the preference
    # of the current payment method, not the intermediately changed one.
    old_stripe_connect.update_columns(type: "Spree::Gateway::StripeSCA")
    changed_method = Spree::PaymentMethod.find(old_stripe_connect.id)
    changed_method.preferred_enterprise_id = owner.id
    old_stripe_connect.update_columns(type: "Spree::Gateway::StripeConnect")
    old_stripe_connect.preferred_enterprise_id = new_owner.id

    subject.up

    expect(result.preferred_enterprise_id).to eq new_owner.id
  end

  it "doesn't mess with new Stripe payment methods" do
    stripe = Spree::Gateway::StripeSCA.create!(
      name: "Modern Stripe",
      environment: "test",
      preferred_enterprise_id: owner.id,
      distributor_ids: [owner.id]
    )

    expect { subject.up }.to_not change { stripe.reload.attributes }
  end

  it "doesn't mess with other payment methods" do
    cash = Spree::PaymentMethod::Check.create!(
      name: "Cash on delivery",
      environment: "test",
      distributor_ids: [owner.id]
    )

    expect { subject.up }.to_not change { cash.reload.attributes }
  end
end
