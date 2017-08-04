require 'spec_helper'

describe InjectionHelper do
  let!(:enterprise) { create(:distributor_enterprise, facebook: "roger") }

  let!(:distributor1) { create(:distributor_enterprise) }
  let!(:distributor2) { create(:distributor_enterprise) }
  let!(:user) { create(:user)}
  let!(:d1o1) { create(:completed_order_with_totals, distributor: distributor1, user_id: user.id, total: 10000)}
  let!(:d1o2) { create(:completed_order_with_totals, distributor: distributor1, user_id: user.id, total: 5000)}
  let!(:d2o1) { create(:completed_order_with_totals, distributor: distributor2, user_id: user.id)}

  it "will inject via AMS" do
    helper.inject_json_ams("test", [enterprise], Api::IdSerializer).should match /#{enterprise.id}/
  end

  it "injects enterprises" do
    helper.inject_enterprises.should match enterprise.name
    helper.inject_enterprises.should match enterprise.facebook
  end

  it "only injects activated enterprises" do
    inactive_enterprise = create(:enterprise, sells: 'unspecified')
    helper.inject_enterprises.should_not match inactive_enterprise.name
  end

  it "injects shipping_methods" do
    sm = create(:shipping_method)
    current_distributor = create(:distributor_enterprise, shipping_methods: [sm])
    order = create(:order, distributor: current_distributor)
    allow(helper).to receive(:current_order) { order }
    allow(helper).to receive(:spree_current_user) { nil }
    helper.inject_available_shipping_methods.should match sm.id.to_s
    helper.inject_available_shipping_methods.should match sm.compute_amount(order).to_s
  end

  it "injects payment methods" do
    pm = create(:payment_method)
    current_distributor = create(:distributor_enterprise, payment_methods: [pm])
    order = create(:order, distributor: current_distributor)
    allow(helper).to receive(:current_order) { order }
    allow(helper).to receive(:spree_current_user) { nil }
    helper.inject_available_payment_methods.should match pm.id.to_s
    helper.inject_available_payment_methods.should match pm.name
  end

  it "injects current order" do
    helper.stub(:current_order).and_return order = create(:order)
    helper.inject_current_order.should match order.id.to_s
  end

  it "injects taxons" do
    taxon = create(:taxon)
    helper.inject_taxons.should match taxon.name
  end

  it "only injects credit cards with a payment profile" do
    allow(helper).to receive(:spree_current_user) { user }
    card1 = create(:credit_card, last_digits: "1234", user_id: user.id, gateway_customer_profile_id: 'cust_123')
    card2 = create(:credit_card, last_digits: "4321", user_id: user.id, gateway_customer_profile_id: nil)
    injected_cards = helper.inject_saved_credit_cards
    expect(injected_cards).to match "1234"
    expect(injected_cards).to_not match "4321"
  end
end
