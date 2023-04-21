# frozen_string_literal: true

require 'spec_helper'

describe PlaceProxyOrder do
  include ActiveSupport::Testing::TimeHelpers

  subject { described_class.new(proxy_order, summarizer, logger, stock_changes_loader) }

  let(:proxy_order) { create(:proxy_order, order: order) }
  let(:order) { build(:order, distributor: build(:enterprise)) }
  let(:summarizer) { OrderManagement::Subscriptions::Summarizer.new }
  let(:logger) { instance_double(JobLogger.logger.class, info: true) }

  let(:mail_mock) { double(:mailer_mock, deliver_now: true) }

  describe "#call" do
    let!(:subscription) { create(:subscription, with_items: true) }
    let!(:proxy_order) { create(:proxy_order, subscription: subscription, order: order) }

    let(:changes) { {} }
    let(:stock_changes_loader) { instance_double(CapQuantity) }

    before do
      allow(stock_changes_loader).to receive(:call).and_return(changes)
      allow(SubscriptionMailer).to receive(:empty_email) { mail_mock }
    end

    it "marks placeable proxy_orders as processed by setting placed_at" do
      freeze_time do
        expect { subject.call }.to change { proxy_order.reload.placed_at }
        expect(proxy_order.placed_at).to eq(Time.zone.now)
      end
    end

    it "tracks exceptions" do
      order.line_items << build(:line_item)

      expect(summarizer).to receive(:record_and_log_error).with(:processing, order, kind_of(String))
      expect(Bugsnag).to receive(:notify).with(kind_of(StandardError))

      subject.call
    end

    context "when the order is already complete" do
      let(:summarizer) {
        instance_double(OrderManagement::Subscriptions::Summarizer, record_order: true)
      }

      let!(:proxy_order) { create(:proxy_order, subscription: subscription) }
      let(:order) { proxy_order.order }

      before do
        proxy_order.initialise_order!
        break unless order.next! while !order.completed?
      end

      it "records an issue and ignores it" do
        expect(summarizer).to receive(:record_issue).with(:complete, order).once
        expect { subject.call }.to_not change { order.reload.state }
        expect(order.payments.first.state).to eq "checkout"
        expect(ActionMailer::Base.deliveries.count).to be 0
      end
    end

    context "when the order is not already complete" do
      describe "selection of shipping method" do
        let(:shop) { create(:distributor_enterprise) }
        let(:shipping_method) { create(:shipping_method, distributors: [shop]) }
        let!(:subscription) do
          create(:subscription, shop: shop, shipping_method: shipping_method, with_items: true)
        end
        let(:proxy_order) { create(:proxy_order, subscription: subscription) }

        before do
          proxy_order.order_cycle.orders_close_at = 1.day.ago
          proxy_order.order_cycle.save!
        end

        it "uses the same shipping method after advancing the order" do
          subject.call

          proxy_order.reload
          expect(proxy_order.state).to eq "complete"
          expect(proxy_order.order.shipping_method).to eq(shipping_method)
        end
      end
    end

    context "when the proxy order fails to generate an order" do
      before do
        allow(proxy_order).to receive(:initialise_order!) { nil }
      end

      it "records an error" do
        expect(summarizer).to receive(:record_subscription_issue)
        subject.call
      end

      it 'does not process the proxy order' do
        subject.call
        expect(proxy_order.reload.placed_at).to be_nil
      end
    end
  end

  describe "#send_placement_email" do
    let(:summarizer) {
      instance_double(OrderManagement::Subscriptions::Summarizer, record_order: true)
    }

    before do
      allow(SubscriptionMailer).to receive(:placement_email) { mail_mock }

      order.line_items << build(:line_item)

      order_workflow = instance_double(OrderWorkflow, complete!: true)
      allow(OrderWorkflow).to receive(:new).with(order).and_return(order_workflow)
    end

    context "when no changes are present" do
      let(:changes) { {} }
      let(:stock_changes_loader) { instance_double(CapQuantity) }

      before do
        allow(stock_changes_loader).to receive(:call).with(order).and_return(changes)
      end

      it "logs a success and sends the email" do
        expect(summarizer).to receive(:record_success).with(order).once

        subject.call

        expect(SubscriptionMailer).to have_received(:placement_email)
        expect(mail_mock).to have_received(:deliver_now)
      end
    end

    context "when changes are present" do
      let(:changes) { double(:changes) }
      let(:stock_changes_loader) { instance_double(CapQuantity) }

      before do
        allow(stock_changes_loader).to receive(:call).with(order).and_return(changes)
      end

      it "logs an issue and sends the email" do
        expect(summarizer).to receive(:record_issue).with(:changes, order).once

        subject.call

        expect(SubscriptionMailer).to have_received(:placement_email).with(order, changes)
        expect(mail_mock).to have_received(:deliver_now)
      end
    end
  end

  describe "#send_empty_email" do
    let(:summarizer) {
      instance_double(OrderManagement::Subscriptions::Summarizer, record_order: true)
    }

    let(:changes) { double(:changes) }
    let(:stock_changes_loader) { instance_double(CapQuantity) }

    before do
      allow(stock_changes_loader).to receive(:call).with(order).and_return(changes)
      allow(SubscriptionMailer).to receive(:empty_email) { mail_mock }
    end

    it "logs an issue and sends the email" do
      expect(summarizer).to receive(:record_issue).with(:empty, order).once

      subject.call

      expect(SubscriptionMailer).to have_received(:empty_email).with(order, changes)
      expect(mail_mock).to have_received(:deliver_now)
    end
  end
end
