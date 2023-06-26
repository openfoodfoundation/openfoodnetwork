# frozen_string_literal: true

require 'spec_helper'

describe InjectionHelper, type: :helper do
  let!(:enterprise) { create(:distributor_enterprise, facebook: "roger") }

  let!(:distributor1) { create(:distributor_enterprise) }
  let!(:distributor2) { create(:distributor_enterprise) }
  let!(:user) { create(:user) }
  let!(:d1o1) {
    create(:completed_order_with_totals, distributor: distributor1, user_id: user.id, total: 10_000)
  }
  let!(:d1o2) {
    create(:completed_order_with_totals, distributor: distributor1, user_id: user.id, total: 5000)
  }
  let!(:d2o1) { create(:completed_order_with_totals, distributor: distributor2, user_id: user.id) }

  it "will inject via AMS" do
    expect(helper.inject_json_array("test", [enterprise],
                                    Api::IdSerializer)).to match /#{enterprise.id}/
  end

  it "injects enterprises" do
    expect(helper.inject_enterprises).to match enterprise.name
    expect(helper.inject_enterprises).to match enterprise.facebook
  end

  it "only injects activated enterprises" do
    inactive_enterprise = create(:enterprise, sells: 'unspecified')
    expect(helper.inject_enterprises).not_to match inactive_enterprise.name
  end

  it "injects shipping_methods" do
    sm = create(:shipping_method)
    current_distributor = create(:distributor_enterprise, shipping_methods: [sm])
    order = create(:order, distributor: current_distributor)
    allow(helper).to receive(:current_order) { order }
    allow(helper).to receive(:spree_current_user) { nil }
  end

  it "injects payment methods" do
    pm = create(:payment_method)
    current_distributor = create(:distributor_enterprise, payment_methods: [pm])
    order = create(:order, distributor: current_distributor)
    allow(helper).to receive(:current_order) { order }
    allow(helper).to receive(:spree_current_user) { nil }
  end

  it "injects current order" do
    allow(helper).to receive(:current_order).and_return order = create(:order)
    expect(helper.inject_current_order).to match order.id.to_s
  end

  describe "injects current order cycle" do
    it "injects empty json object (not nil) when current OC is null" do
      allow(helper).to receive(:current_order_cycle).and_return nil
      expect(helper.inject_current_order_cycle).to match "{}"
    end

    it "injects current OC when OC not null" do
      allow(helper).to receive(:current_order_cycle)
        .and_return order_cycle = create(:simple_order_cycle)
      expect(helper.inject_current_order_cycle).to match order_cycle.id.to_s
    end
  end

  it "injects taxons" do
    taxon = create(:taxon)
    expect(helper.inject_taxons).to match taxon.name
  end

  it "only injects credit cards with a payment profile" do
    allow(helper).to receive(:spree_current_user) { user }
    card1 = create(:credit_card, last_digits: "1234", user_id: user.id,
                                 gateway_customer_profile_id: 'cust_123')
    card2 = create(:credit_card, last_digits: "4321", user_id: user.id,
                                 gateway_customer_profile_id: nil)
    injected_cards = helper.inject_saved_credit_cards
    expect(injected_cards).to match "1234"
    expect(injected_cards).to_not match "4321"
  end
end
