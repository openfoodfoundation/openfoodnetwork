# frozen_string_literal: true

require 'spec_helper'

describe ProxyOrder, type: :model do
  describe "cancel" do
    let(:order_cycle) { create(:simple_order_cycle) }
    let(:subscription) { create(:subscription) }

    around do |example|
      # We are testing if database columns have been set to "now".
      Timecop.freeze(Time.zone.now) { example.run }
    end

    context "when the order cycle is not yet closed" do
      let(:proxy_order) {
        create(:proxy_order, subscription: subscription, order: order, order_cycle: order_cycle)
      }
      before { order_cycle.update(orders_open_at: 1.day.ago, orders_close_at: 3.days.from_now) }

      context "and an order has not been initialised" do
        let(:order) { nil }

        it "returns true and sets canceled_at to the current time" do
          expect(proxy_order.cancel).to be true
          expect_cancelled_now proxy_order
          expect(proxy_order.state).to eq 'canceled'
        end
      end

      context "and the order has already been completed" do
        let(:order) { create(:completed_order_with_totals) }

        it "returns true and sets canceled_at to the current time, and cancels the order" do
          expect(Spree::OrderMailer).to receive(:cancel_email) {
                                          double(:email, deliver_later: true)
                                        }
          expect(proxy_order.cancel).to be true
          expect_cancelled_now proxy_order
          expect(order.reload.state).to eq 'canceled'
          expect(proxy_order.state).to eq 'canceled'
        end
      end

      context "and the order has not already been completed" do
        let(:order) { create(:order) }

        it "returns true and sets canceled_at to the current time" do
          expect(proxy_order.cancel).to be true
          expect_cancelled_now proxy_order
          expect(order.reload.state).to eq 'cart'
          expect(proxy_order.state).to eq 'canceled'
        end
      end
    end

    context "when the order cycle is already closed" do
      let(:proxy_order) {
        create(:proxy_order, subscription: subscription, order: order, order_cycle: order_cycle)
      }
      before { order_cycle.update(orders_open_at: 3.days.ago, orders_close_at: 1.minute.ago) }

      context "and an order has not been initialised" do
        let(:order) { nil }

        it "returns false and does nothing" do
          expect(proxy_order.cancel).to be false
          expect(proxy_order.reload.canceled_at).to be nil
          expect(proxy_order.state).to eq 'pending'
        end
      end

      context "and an order has been initialised" do
        let(:order) { create(:order) }

        it "returns false and does nothing" do
          expect(proxy_order.cancel).to be false
          expect(proxy_order.reload.canceled_at).to be nil
          expect(order.reload.state).to eq 'cart'
          expect(proxy_order.state).to eq 'cart'
        end
      end
    end
  end

  describe "resume" do
    let!(:shipment) { create(:shipment) }
    let(:order) {
      create(:order_with_totals, ship_address: create(:address),
                                 shipments: [shipment],
                                 payments: [create(:payment)],
                                 distributor: shipment.shipping_method.distributors.first)
    }
    let(:proxy_order) { create(:proxy_order, order: order, canceled_at: Time.zone.now) }
    let(:order_cycle) { proxy_order.order_cycle }

    around do |example|
      Timecop.freeze(Time.zone.now) { example.run }
    end

    context "when the order cycle is not yet closed" do
      before { order_cycle.update(orders_open_at: 1.day.ago, orders_close_at: 3.days.from_now) }

      context "and the order has not been initialised" do
        let(:order) { nil }

        it "returns true and clears canceled_at" do
          expect(proxy_order.resume).to be true
          expect(proxy_order.reload.canceled_at).to be nil
          expect(proxy_order.state).to eq 'pending'
        end
      end

      context "and the order has already been cancelled" do
        before do
          allow(Spree::OrderMailer).to receive(:cancel_email) {
                                         double(:email, deliver_later: true)
                                       }
          break unless order.next! while !order.completed?
          order.cancel
          order.reload
        end

        it "returns true, clears canceled_at and resumes the order" do
          expect(proxy_order.resume).to be true
          expect(proxy_order.reload.canceled_at).to be nil
          expect(order.reload.state).to eq 'resumed'
          expect(proxy_order.state).to eq 'resumed'
        end
      end

      context "and the order has not been cancelled" do
        before { break unless order.next! while !order.completed? }

        it "returns true and clears canceled_at" do
          expect(proxy_order.resume).to be true
          expect(proxy_order.reload.canceled_at).to be nil
          expect(order.reload.state).to eq 'complete'
          expect(proxy_order.state).to eq 'cart'
        end
      end
    end

    context "when the order cycle is already closed" do
      before { order_cycle.update(orders_open_at: 3.days.ago, orders_close_at: 1.minute.ago) }

      context "and the order has not been initialised" do
        let(:order) { nil }

        it "returns false and does nothing" do
          expect(proxy_order.resume).to eq false
          expect_cancelled_now proxy_order
          expect(proxy_order.state).to eq 'canceled'
        end
      end

      context "and the order has been cancelled" do
        before do
          allow(Spree::OrderMailer).to receive(:cancel_email) {
                                         double(:email, deliver_later: true)
                                       }
          break unless order.next! while !order.completed?
          order.cancel
        end

        it "returns false and does nothing" do
          expect(proxy_order.resume).to eq false
          expect_cancelled_now proxy_order
          expect(order.reload.state).to eq 'canceled'
          expect(proxy_order.state).to eq 'canceled'
        end
      end

      context "and the order has not been cancelled" do
        before { break unless order.next! while !order.completed? }

        it "returns false and does nothing" do
          expect(proxy_order.resume).to eq false
          expect_cancelled_now proxy_order
          expect(order.reload.state).to eq 'complete'
          expect(proxy_order.state).to eq 'canceled'
        end
      end
    end
  end

  describe "initialise_order!" do
    let(:order) { create(:order) }
    let(:factory) { instance_double(OrderFactory) }
    let!(:proxy_order) { create(:proxy_order) }

    context "when the order has not already been initialised" do
      it "creates a new order using the OrderFactory, and returns it" do
        expect(OrderFactory).to receive(:new) { factory }
        expect(factory).to receive(:create) { order }
        expect(proxy_order.initialise_order!).to eq order
      end
    end

    context "when the order has already been initialised" do
      let(:existing_order) { create(:order) }

      before do
        proxy_order.update(order: existing_order)
      end

      it "returns the existing order" do
        expect(OrderFactory).to_not receive(:new)
        expect(proxy_order).to_not receive(:save!)
        expect(proxy_order.initialise_order!).to eq existing_order
      end
    end
  end

  private

  def expect_cancelled_now(subject)
    # We still need to use be_within, because the Database timestamp is not as
    # accurate as the Rails timestamp. If we use `eq`, we have differing nano
    # seconds.
    expect(subject.reload.canceled_at).to be_within(2.seconds).of Time.zone.now
  end
end
