# frozen_string_literal: true

require 'spec_helper'

describe Subscription, type: :model do
  describe "associations" do
    it { expect(subject).to belong_to(:shop).optional }
    it { expect(subject).to belong_to(:customer).optional }
    it { expect(subject).to belong_to(:schedule).optional }
    it { expect(subject).to belong_to(:shipping_method).optional }
    it { expect(subject).to belong_to(:payment_method).optional }
    it { expect(subject).to belong_to(:ship_address).optional }
    it { expect(subject).to belong_to(:bill_address).optional }
    it { expect(subject).to have_many(:subscription_line_items) }
    it { expect(subject).to have_many(:order_cycles) }
    it { expect(subject).to have_many(:proxy_orders) }
    it { expect(subject).to have_many(:orders) }
  end

  describe "cancel" do
    let!(:subscription) { create(:subscription) }
    let!(:proxy_order1) { create(:proxy_order, order_cycle: create(:simple_order_cycle)) }
    let!(:proxy_order2) { create(:proxy_order, order_cycle: create(:simple_order_cycle)) }

    before do
      allow(subscription).to receive(:proxy_orders) { [proxy_order1, proxy_order2] }
    end

    context "when all subscription orders can be cancelled" do
      before { allow(proxy_order1).to receive(:cancel) { true } }
      before { allow(proxy_order2).to receive(:cancel) { true } }

      it "marks the subscription as cancelled and calls #cancel on all proxy_orders" do
        subscription.cancel
        expect(subscription.reload.canceled_at).to be_within(5.seconds).of Time.zone.now
        expect(proxy_order1).to have_received(:cancel)
        expect(proxy_order2).to have_received(:cancel)
      end
    end

    context "when a subscription order cannot be cancelled" do
      before { allow(proxy_order1).to receive(:cancel).and_raise("Some error") }
      before { allow(proxy_order2).to receive(:cancel) { true } }

      it "aborts the transaction" do
        # ie. canceled_at remains as nil, #cancel not called on second subscription order
        expect{ subscription.cancel }.to raise_error "Some error"
        expect(subscription.reload.canceled_at).to be nil
        expect(proxy_order1).to have_received(:cancel)
        expect(proxy_order2).to_not have_received(:cancel)
      end
    end
  end

  describe "state" do
    let(:subscription) { Subscription.new }

    context "when the subscription has been cancelled" do
      before { allow(subscription).to receive(:canceled_at) { Time.zone.now } }

      it "returns 'canceled'" do
        expect(subscription.state).to eq 'canceled'
      end
    end

    context "when the subscription has not been cancelled" do
      before { allow(subscription).to receive(:canceled_at) { nil } }

      context "and the subscription has been paused" do
        before { allow(subscription).to receive(:paused_at) { Time.zone.now } }

        it "returns 'paused'" do
          expect(subscription.state).to eq 'paused'
        end
      end

      context "and the subscription has not been paused" do
        before { allow(subscription).to receive(:paused_at) { nil } }

        context "and the subscription has no begins_at date" do
          before { allow(subscription).to receive(:begins_at) { nil } }

          it "returns 'pending'" do
            expect(subscription.state).to eq 'pending'
          end
        end

        context "and the subscription has a begins_at date in the future" do
          before { allow(subscription).to receive(:begins_at) { 1.minute.from_now } }

          it "returns 'pending'" do
            expect(subscription.state).to eq 'pending'
          end
        end

        context "and the subscription has a begins_at date in the past" do
          before { allow(subscription).to receive(:begins_at) { 1.minute.ago } }

          context "and the subscription has no ends_at date set" do
            before { allow(subscription).to receive(:ends_at) { nil } }

            it "returns 'active'" do
              expect(subscription.state).to eq 'active'
            end
          end

          context "and the subscription has an ends_at date in the future" do
            before { allow(subscription).to receive(:ends_at) { 1.minute.from_now } }

            it "returns 'active'" do
              expect(subscription.state).to eq 'active'
            end
          end

          context "and the subscription has an ends_at date in the past" do
            before { allow(subscription).to receive(:ends_at) { 1.minute.ago } }

            it "returns 'ended'" do
              expect(subscription.state).to eq 'ended'
            end
          end
        end
      end
    end
  end
end
