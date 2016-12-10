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
    let!(:proxy_order1) { standing_order.proxy_orders.first }
    let!(:proxy_order2) { standing_order.proxy_orders.last }

    before do
      allow(standing_order).to receive(:proxy_orders) { [proxy_order1, proxy_order2] }
    end

    context "when all standing order orders can be cancelled" do
      before { allow(proxy_order1).to receive(:cancel) { true } }
      before { allow(proxy_order2).to receive(:cancel) { true } }

      it "marks the standing order as cancelled and calls #cancel on all proxy_orders" do
        standing_order.cancel
        expect(standing_order.reload.canceled_at).to be_within(5.seconds).of Time.now
        expect(proxy_order1).to have_received(:cancel)
        expect(proxy_order2).to have_received(:cancel)
      end
    end

    context "when a standing order order cannot be cancelled" do
      before { allow(proxy_order1).to receive(:cancel).and_raise("Some error") }
      before { allow(proxy_order2).to receive(:cancel) { true } }

      it "aborts the transaction" do
        # ie. canceled_at remains as nil, #cancel not called on second standing order order
        expect{standing_order.cancel}.to raise_error "Some error"
        expect(standing_order.reload.canceled_at).to be nil
        expect(proxy_order1).to have_received(:cancel)
        expect(proxy_order2).to_not have_received(:cancel)
      end
    end
  end

  describe "state" do
    let(:standing_order) { StandingOrder.new }

    context "when the standing order has been cancelled" do
      before { allow(standing_order).to receive(:canceled_at) { Time.zone.now } }

      it "returns 'canceled'" do
        expect(standing_order.state).to eq 'canceled'
      end
    end

    context "when the standing order has not been cancelled" do
      before { allow(standing_order).to receive(:canceled_at) { nil } }

      context "and the standing order has been paused" do
        before { allow(standing_order).to receive(:paused_at) { Time.zone.now } }

        it "returns 'paused'" do
          expect(standing_order.state).to eq 'paused'
        end
      end

      context "and the standing order has not been paused" do
        before { allow(standing_order).to receive(:paused_at) { nil } }

        context "and the standing order has no begins_at date" do
          before { allow(standing_order).to receive(:begins_at) { nil } }

          it "returns nil" do
            expect(standing_order.state).to be nil
          end
        end

        context "and the standing order has a begins_at date in the future" do
          before { allow(standing_order).to receive(:begins_at) { 1.minute.from_now } }

          it "returns 'pending'" do
            expect(standing_order.state).to eq 'pending'
          end
        end

        context "and the standing order has a begins_at date in the past" do
          before { allow(standing_order).to receive(:begins_at) { 1.minute.ago } }

          context "and the standing order has no ends_at date set" do
            before { allow(standing_order).to receive(:ends_at) { nil } }

            it "returns 'active'" do
              expect(standing_order.state).to eq 'active'
            end
          end

          context "and the standing order has an ends_at date in the future" do
            before { allow(standing_order).to receive(:ends_at) { 1.minute.from_now } }

            it "returns 'active'" do
              expect(standing_order.state).to eq 'active'
            end
          end

          context "and the standing order has an ends_at date in the past" do
            before { allow(standing_order).to receive(:ends_at) { 1.minute.ago } }

            it "returns 'ended'" do
              expect(standing_order.state).to eq 'ended'
            end
          end
        end
      end
    end
  end
end
