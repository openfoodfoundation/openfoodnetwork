require 'spec_helper'

describe StandingOrder, type: :model do
  describe "validations" do
    let(:shop) { create(:distributor_enterprise) }

    context "shop" do
      it { expect(subject).to validate_presence_of :shop }
    end

    context "customer" do
      it { expect(subject).to validate_presence_of :customer }

      let(:c1) { create(:customer, enterprise: shop) }
      let(:c2) { create(:customer, enterprise: create(:enterprise)) }
      let(:so1) { build(:standing_order, shop: shop, customer: c1) }
      let(:so2) { build(:standing_order, shop: shop, customer: c2) }

      it "requires customer to be available to shop" do
        expect(so1.valid?).to be true
        expect(so2.valid?).to be false
        expect(so2.errors[:customer]).to eq ["does not belong to #{shop.name}"]
      end
    end

    it "requires a schedule" do
      expect(subject).to validate_presence_of :schedule
    end

    context "schedule" do
      it { expect(subject).to validate_presence_of :schedule }

      let(:s1) { create(:schedule, order_cycles: [create(:simple_order_cycle, coordinator: shop)]) }
      let(:s2) { create(:schedule, order_cycles: [create(:simple_order_cycle, coordinator: create(:enterprise))]) }
      let(:so1) { build(:standing_order, shop: shop, schedule: s1) }
      let(:so2) { build(:standing_order, shop: shop, schedule: s2) }

      it "requires schedule to be available to shop" do
        expect(so1.valid?).to be true
        expect(so2.valid?).to be false
        expect(so2.errors[:schedule]).to eq ["is not coordinated by #{shop.name}"]
      end
    end

    context "payment_method" do
      it { expect(subject).to validate_presence_of :payment_method }

      let(:pm1) { create(:payment_method, distributors: [shop]) }
      let(:pm2) { create(:payment_method, distributors: [create(:enterprise)]) }
      let(:so1) { build(:standing_order, shop: shop, payment_method: pm1) }
      let(:so2) { build(:standing_order, shop: shop, payment_method: pm2) }

      it "requires payment_method to be available to shop" do
        expect(so1.valid?).to be true
        expect(so2.valid?).to be false
        expect(so2.errors[:payment_method]).to eq ["is not available to #{shop.name}"]
      end
    end


    context "shipping_method" do
      it { expect(subject).to validate_presence_of :shipping_method }

      let(:sm1) { create(:shipping_method, distributors: [shop]) }
      let(:sm2) { create(:shipping_method, distributors: [create(:enterprise)]) }
      let(:so1) { build(:standing_order, shop: shop, shipping_method: sm1) }
      let(:so2) { build(:standing_order, shop: shop, shipping_method: sm2) }

      it "requires shipping_method to be available to shop" do
        expect(so1.valid?).to be true
        expect(so2.valid?).to be false
        expect(so2.errors[:shipping_method]).to eq ["is not available to #{shop.name}"]
      end
    end

    it "requires a billing_address" do
      expect(subject).to validate_presence_of :billing_address
    end

    it "requires a shipping_address" do
      expect(subject).to validate_presence_of :shipping_address
    end

    it "requires a begins_at date" do
      expect(subject).to validate_presence_of :begins_at
    end
  end

  describe "cancel" do
    let!(:standing_order) { create(:standing_order, orders: [create(:order), create(:order)]) }
    let!(:standing_order_order1) { standing_order.standing_order_orders.first }
    let!(:standing_order_order2) { standing_order.standing_order_orders.last }

    before do
      allow(standing_order).to receive(:standing_order_orders) { [standing_order_order1, standing_order_order2] }
    end

    context "when all standing order orders can be cancelled" do
      before { allow(standing_order_order1).to receive(:cancel) { true } }
      before { allow(standing_order_order2).to receive(:cancel) { true } }

      it "marks the standing order as cancelled and calls #cancel on all standing_order_orders" do
        standing_order.cancel
        expect(standing_order.reload.canceled_at).to be_within(5.seconds).of Time.now
        expect(standing_order_order1).to have_received(:cancel)
        expect(standing_order_order2).to have_received(:cancel)
      end
    end

    context "when a standing order order cannot be cancelled" do
      before { allow(standing_order_order1).to receive(:cancel).and_raise("Some error") }
      before { allow(standing_order_order2).to receive(:cancel) { true } }

      it "aborts the transaction" do
        # ie. canceled_at remains as nil, #cancel not called on second standing order order
        expect{standing_order.cancel}.to raise_error "Some error"
        expect(standing_order.reload.canceled_at).to be nil
        expect(standing_order_order1).to have_received(:cancel)
        expect(standing_order_order2).to_not have_received(:cancel)
      end
    end
  end
end
