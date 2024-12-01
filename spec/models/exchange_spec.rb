# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Exchange do
  it { is_expected.to have_many :semantic_links }

  it "should be valid when built from factory" do
    expect(build(:exchange)).to be_valid
  end

  [:order_cycle, :sender, :receiver].each do |attr|
    it "should not be valid without #{attr}" do
      e = build(:exchange)
      e.__send__("#{attr}=", nil)
      expect(e).not_to be_valid
    end
  end

  it "shouldn't be valid when (sender, receiver, direction) set aren't unique for its OC" do
    e1 = create(:exchange)

    e2 = build(:exchange,
               order_cycle: e1.order_cycle, sender: e1.sender, receiver: e1.receiver,
               incoming: e1.incoming)
    expect(e2).not_to be_valid

    e2.incoming = !e2.incoming
    expect(e2).to be_valid
    e2.incoming = !e2.incoming

    e2.receiver = create(:enterprise)
    expect(e2).to be_valid

    e2.sender = e2.receiver
    e2.receiver = e1.receiver
    expect(e2).to be_valid
  end

  it "has exchange variants" do
    e = create(:exchange)
    p = create(:product)

    e.exchange_variants.create(variant: p.variants.first)
    expect(e.variants.count).to eq(1)
  end

  it "has exchange fees" do
    e = create(:exchange)
    f = create(:enterprise_fee)

    e.exchange_fees.create(enterprise_fee: f)
    expect(e.enterprise_fees.count).to eq(1)
  end

  describe "exchange directionality" do
    let(:supplier) { create(:supplier_enterprise) }
    let(:coordinator) { create(:distributor_enterprise) }
    let(:distributor) { create(:distributor_enterprise) }
    let(:oc) { create(:simple_order_cycle, coordinator:) }
    let(:incoming_exchange) {
      oc.exchanges.create! sender: supplier, receiver: coordinator, incoming: true
    }
    let(:outgoing_exchange) {
      oc.exchanges.create! sender: coordinator, receiver: distributor, incoming: false
    }

    describe "reporting whether it is an incoming exchange" do
      it "returns true for incoming exchanges" do
        expect(incoming_exchange).to be_incoming
      end

      it "returns false for outgoing exchanges" do
        expect(outgoing_exchange).not_to be_incoming
      end
    end

    describe "finding the exchange participant (the enterprise other than the coordinator)" do
      it "returns the sender for incoming exchanges" do
        expect(incoming_exchange.participant).to eq(supplier)
      end

      it "returns the receiver for outgoing exchanges" do
        expect(outgoing_exchange.participant).to eq(distributor)
      end
    end
  end

  describe "reporting its role" do
    it "returns 'supplier' when it is an incoming exchange" do
      e = Exchange.new
      allow(e).to receive(:incoming?) { true }
      expect(e.role).to eq('supplier')
    end

    it "returns 'distributor' when it is an outgoing exchange" do
      e = Exchange.new
      allow(e).to receive(:incoming?) { false }
      expect(e.role).to eq('distributor')
    end
  end

  describe "scopes" do
    let(:supplier) { create(:supplier_enterprise) }
    let(:coordinator) { create(:distributor_enterprise, is_primary_producer: true) }
    let(:distributor) { create(:distributor_enterprise) }
    let(:oc) { create(:simple_order_cycle, coordinator:) }

    describe "finding exchanges managed by a particular user" do
      let(:user) do
        user = create(:user)
        user.spree_roles = []
        user
      end

      before { Exchange.destroy_all }

      it "returns exchanges where the user manages both the sender and the receiver" do
        exchange = create(:exchange, order_cycle: oc)
        exchange.sender.users << user
        exchange.receiver.users << user

        expect(Exchange.managed_by(user)).to eq([exchange])
      end

      it "does not return exchanges where the user manages only the sender" do
        exchange = create(:exchange, order_cycle: oc)
        exchange.sender.users << user

        expect(Exchange.managed_by(user)).to be_empty
      end

      it "does not return exchanges where the user manages only the receiver" do
        exchange = create(:exchange, order_cycle: oc)
        exchange.receiver.users << user

        expect(Exchange.managed_by(user)).to be_empty
      end

      it "does not return exchanges where the user manages neither enterprise" do
        exchange = create(:exchange, order_cycle: oc)
        expect(Exchange.managed_by(user)).to be_empty
      end
    end

    it "finds exchanges in a particular order cycle" do
      ex = create(:exchange, order_cycle: oc)
      expect(Exchange.in_order_cycle(oc)).to eq([ex])
    end

    describe "finding exchanges by direction" do
      let!(:incoming_exchange) {
        oc.exchanges.create! sender: supplier,    receiver: coordinator, incoming: true
      }
      let!(:outgoing_exchange) {
        oc.exchanges.create! sender: coordinator, receiver: distributor, incoming: false
      }

      it "finds incoming exchanges" do
        expect(Exchange.incoming).to eq([incoming_exchange])
      end

      it "finds outgoing exchanges" do
        expect(Exchange.outgoing).to eq([outgoing_exchange])
      end

      it "correctly determines direction of exchanges between the same enterprise" do
        incoming_exchange.update sender: coordinator, incoming: true
        outgoing_exchange.update receiver: coordinator, incoming: false
        expect(Exchange.incoming).to eq([incoming_exchange])
        expect(Exchange.outgoing).to eq([outgoing_exchange])
      end

      it "finds exchanges coming from an enterprise" do
        expect(Exchange.from_enterprise(supplier)).to    eq([incoming_exchange])
        expect(Exchange.from_enterprise(coordinator)).to eq([outgoing_exchange])
      end

      it "finds exchanges going to an enterprise" do
        expect(Exchange.to_enterprise(coordinator)).to eq([incoming_exchange])
        expect(Exchange.to_enterprise(distributor)).to eq([outgoing_exchange])
      end

      it "finds exchanges coming from any of a number of enterprises" do
        expect(Exchange.from_enterprises([coordinator])).to eq([outgoing_exchange])
        expect(Exchange.from_enterprises([supplier,
                                          coordinator])).to match_array [incoming_exchange,
                                                                         outgoing_exchange]
      end

      it "finds exchanges going to any of a number of enterprises" do
        expect(Exchange.to_enterprises([coordinator])).to eq([incoming_exchange])
        expect(Exchange.to_enterprises([coordinator,
                                        distributor])).to match_array [incoming_exchange,
                                                                       outgoing_exchange]
      end

      it "finds exchanges involving any of a number of enterprises" do
        expect(Exchange.involving([supplier])).to eq([incoming_exchange])
        expect(Exchange.involving([coordinator])).to match_array [incoming_exchange,
                                                                  outgoing_exchange]
        expect(Exchange.involving([distributor])).to eq([outgoing_exchange])
      end
    end

    describe "finding exchanges supplying to a distributor" do
      it "returns incoming exchanges" do
        d = create(:distributor_enterprise)
        ex = create(:exchange, order_cycle: oc, incoming: true)

        expect(oc.exchanges.supplying_to(d)).to eq([ex])
      end

      it "returns outgoing exchanges to the distributor" do
        d = create(:distributor_enterprise)
        ex = create(:exchange, order_cycle: oc, receiver: d, incoming: false)

        expect(oc.exchanges.supplying_to(d)).to eq([ex])
      end

      it "does not return outgoing exchanges to a different distributor" do
        d1 = create(:distributor_enterprise)
        d2 = create(:distributor_enterprise)
        ex = create(:exchange, order_cycle: oc, receiver: d1, incoming: false)

        expect(oc.exchanges.supplying_to(d2)).to be_empty
      end
    end

    it "finds exchanges with a particular variant" do
      v = create(:variant)
      ex = create(:exchange)
      ex.variants << v

      expect(Exchange.with_variant(v)).to eq([ex])
    end

    it "finds exchanges with any of a number of variants, without returning duplicates" do
      v1 = create(:variant)
      v2 = create(:variant)
      v3 = create(:variant)
      ex = create(:exchange)
      ex.variants << v1
      ex.variants << v2

      expect(Exchange.with_any_variant([v1.id, v2.id, v3.id])).to eq([ex])
    end

    it "finds exchanges with a particular product's variant" do
      p = create(:simple_product)
      v = create(:variant, product: p)
      ex = create(:exchange)
      ex.variants << v
      p.reload

      expect(Exchange.with_product(p)).to eq([ex])
    end

    describe "sorting exchanges by primary enterprise name" do
      let(:e1) { create(:supplier_enterprise,    name: 'ZZZ') }
      let(:e2) { create(:distributor_enterprise, name: 'AAA') }
      let(:e3) { create(:supplier_enterprise,    name: 'CCC') }

      let!(:ex1) { create(:exchange, sender:   e1, incoming: true) }
      let!(:ex2) { create(:exchange, receiver: e2, incoming: false) }
      let!(:ex3) { create(:exchange, sender:   e3, incoming: true) }

      it "sorts" do
        expect(Exchange.by_enterprise_name).to eq([ex2, ex3, ex1])
      end
    end
  end

  it "clones itself" do
    oc = create(:order_cycle)
    new_oc = create(:simple_order_cycle)

    ex1 = oc.exchanges.last
    ex1.update_attribute(:tag_list, "wholesale")
    ex2 = ex1.reload.clone! new_oc

    expect(ex1.sender_id).to eq ex2.sender_id
    expect(ex1.receiver_id).to eq ex2.receiver_id
    expect(ex1.pickup_time).to eq ex2.pickup_time
    expect(ex1.pickup_instructions).to eq ex2.pickup_instructions
    expect(ex1.incoming).to eq ex2.incoming
    expect(ex1.receival_instructions).to eq ex2.receival_instructions
    expect(ex1.variant_ids).to eq ex2.variant_ids
    expect(ex1.enterprise_fee_ids).to eq ex2.enterprise_fee_ids

    expect(ex2.reload.tag_list).to eq ["wholesale"]
  end
end
