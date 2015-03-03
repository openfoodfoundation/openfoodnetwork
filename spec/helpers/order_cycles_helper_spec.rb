require 'spec_helper'

describe OrderCyclesHelper do
  describe "finding producer enterprise options" do
    before do
      helper.stub(:order_cycle_producer_enterprises) { "enterprise list" }
    end

    it "asks for a validation option list" do
      expect(helper).to receive(:validated_enterprise_options).with("enterprise list", {confirmed: true})
      helper.order_cycle_producer_enterprise_options
    end
  end

  describe "finding coodinator enterprise options" do
    before do
      helper.stub(:order_cycle_coordinating_enterprises) { "enterprise list" }
    end

    it "asks for a validation option list" do
      expect(helper).to receive(:validated_enterprise_options).with("enterprise list", {confirmed: true})
      helper.order_cycle_coordinating_enterprise_options
    end
  end

  describe "finding hub enterprise options" do
    before do
      helper.stub(:order_cycle_hub_enterprises) { "enterprise list" }
    end

    it "asks for a validation option list" do
      expect(helper).to receive(:validated_enterprise_options).with("enterprise list", {confirmed: true, shipping_and_payment_methods: true})
      helper.order_cycle_hub_enterprise_options
    end
  end

  describe "building a validated enterprise list" do
    let(:e) { create(:distributor_enterprise, name: 'enterprise') }

    before do
      helper.stub(:order_cycle_permitted_enterprises) { Enterprise.where(id: e.id) }
    end

    it "returns enterprises without shipping methods as disabled" do
      create(:payment_method, distributors: [e])
      expect(helper.send(:validated_enterprise_options, [e], shipping_and_payment_methods: true))
      .to eq [['enterprise (no shipping methods)', e.id, {disabled: true}]]
    end

    it "returns enterprises without payment methods as disabled" do
      create(:shipping_method, distributors: [e])
      expect(helper.send(:validated_enterprise_options, [e], shipping_and_payment_methods: true))
      .to eq [['enterprise (no payment methods)', e.id, {disabled: true}]]
    end

    it "returns enterprises with unavailable payment methods as disabled" do
      create(:shipping_method, distributors: [e])
      create(:payment_method, distributors: [e], active: false)
      expect(helper.send(:validated_enterprise_options, [e], shipping_and_payment_methods: true))
      .to eq [['enterprise (no payment methods)', e.id, {disabled: true}]]
    end

    it "returns unconfirmed enterprises as disabled" do
      create(:shipping_method, distributors: [e])
      create(:payment_method, distributors: [e])
      e.stub(:confirmed_at) { nil }
      expect(helper.send(:validated_enterprise_options, [e], confirmed: true))
      .to eq [['enterprise (unconfirmed)', e.id, {disabled: true}]]
    end

    it "returns enterprises with neither shipping nor payment methods as disabled" do
      expect(helper.send(:validated_enterprise_options, [e], shipping_and_payment_methods: true))
      .to eq [['enterprise (no shipping or payment methods)', e.id, {disabled: true}]]
    end
  end

  describe "pickup time" do
    it "gives me the pickup time for the current order cycle" do
      d = create(:distributor_enterprise, name: 'Green Grass')
      oc1 = create(:simple_order_cycle, name: 'oc 1', distributors: [d])
      exchange = Exchange.find(oc1.exchanges.to_enterprises(d).outgoing.first.id)
      exchange.update_attribute :pickup_time, "turtles"

      helper.stub(:current_order_cycle).and_return oc1
      helper.stub(:current_distributor).and_return d
      helper.pickup_time.should == "turtles"
    end

    it "gives me the pickup time for any order cycle" do
      d = create(:distributor_enterprise, name: 'Green Grass')
      oc1 = create(:simple_order_cycle, name: 'oc 1', distributors: [d])
      oc2= create(:simple_order_cycle, name: 'oc 1', distributors: [d])

      exchange = Exchange.find(oc2.exchanges.to_enterprises(d).outgoing.first.id)
      exchange.update_attribute :pickup_time, "turtles"

      helper.stub(:current_order_cycle).and_return oc1
      helper.stub(:current_distributor).and_return d
      helper.pickup_time(oc2).should == "turtles"
    end
  end
end
