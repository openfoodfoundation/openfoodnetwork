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
end
