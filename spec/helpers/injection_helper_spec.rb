# frozen_string_literal: true

RSpec.describe InjectionHelper do
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

  let(:sm) { create(:shipping_method) }
  let(:pm) { create(:payment_method) }
  let(:distributor) {
    create(:distributor_enterprise, shipping_methods: [sm], payment_methods: [pm])
  }
  let(:order) { create(:order, distributor:) }

  before do
    allow_any_instance_of(EnterprisesHelper).to receive(:current_distributor).and_return distributor
    allow_any_instance_of(EnterprisesHelper).to receive(:current_order).and_return order
  end

  it "will inject via AMS" do
    expect(helper.inject_json_array("test", [enterprise],
                                    Api::IdSerializer)).to match /#{enterprise.id}/
  end

  describe "#inject_enterprises" do
    it "injects enterprises" do
      expect(helper.inject_enterprises).to match enterprise.name
      expect(helper.inject_enterprises).to match enterprise.facebook
    end

    it "only injects activated enterprises" do
      inactive_enterprise = create(:enterprise, sells: 'unspecified')
      expect(helper.inject_enterprises).not_to match inactive_enterprise.name
    end
  end

  describe "#inject_enterprise_and_relatives" do
    let(:child) { create :distributor_enterprise }
    let!(:relationship) { create :enterprise_relationship, parent: distributor, child: }

    it "injects the current distributor and its relatives" do
      expect(helper.inject_enterprise_and_relatives).to match distributor.name
      expect(helper.inject_enterprise_and_relatives).to match child.name
    end
  end

  describe "#inject_group_enterprises" do
    let(:group) { create :enterprise_group, enterprises: [enterprise] }

    it "injects an enterprise group's enterprises" do
      expect(helper.inject_group_enterprises(group)).to match enterprise.name
    end
  end

  describe "#inject_current_hub" do
    it "injects the current distributor" do
      expect(helper.inject_current_hub).to match distributor.name
    end
  end

  it "injects current order" do
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
    expect(injected_cards).not_to match "4321"
  end
end
