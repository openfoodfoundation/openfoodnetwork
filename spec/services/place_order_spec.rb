# frozen_string_literal: true

require 'spec_helper'

describe PlaceOrder do
  subject { described_class.new(proxy_order, summarizer, logger, changes) }

  let(:changes) { {} }
  let(:proxy_order) { create(:proxy_order, order: order) }
  let(:order) { build(:order) }
  let(:summarizer) { instance_double(OrderManagement::Subscriptions::Summarizer) }
  let(:logger) { instance_double(JobLogger.logger.class, info: true) }

  let(:mail_mock) { double(:mailer_mock, deliver_now: true) }

  describe "#call" do
    let!(:subscription) { create(:subscription, with_items: true) }
    let!(:proxy_order) { create(:proxy_order, subscription: subscription, order: order) }

    let(:changes) { lambda { {} } }
    let(:summarizer) { instance_double(OrderManagement::Subscriptions::Summarizer, record_order: true, record_issue: true) }

    before do
      allow(SubscriptionMailer).to receive(:empty_email) { mail_mock }
      subject.initialise_order
    end

    it "marks placeable proxy_orders as processed by setting placed_at" do
      expect{ subject.call(order, subject) }.to change{ proxy_order.reload.placed_at }
      expect(proxy_order.placed_at).to be_within(5.seconds).of Time.zone.now
    end
  end

  describe "#send_placement_email" do
    let(:summarizer) { instance_double(OrderManagement::Subscriptions::Summarizer, record_order: true) }

    before do
      allow(SubscriptionMailer).to receive(:placement_email) { mail_mock }
    end

    before do
      order.line_items << build(:line_item)

      order_workflow = instance_double(OrderWorkflow, complete!: true)
      allow(OrderWorkflow).to receive(:new).with(order).and_return(order_workflow)
    end

    context "when no changes are present" do
      let(:changes) { lambda { {} } }

      it "logs a success and sends the email" do
        expect(summarizer).to receive(:record_success).with(order).once

        subject.call

        expect(SubscriptionMailer).to have_received(:placement_email)
        expect(mail_mock).to have_received(:deliver_now)
      end
    end

    context "when changes are present" do
      let(:changeset) { double(:changes) }
      let(:changes) { lambda { changeset } }

      it "logs an issue and sends the email" do
        expect(summarizer).to receive(:record_issue).with(:changes, order).once

        subject.call

        expect(SubscriptionMailer).to have_received(:placement_email).with(order, changeset)
        expect(mail_mock).to have_received(:deliver_now)
      end
    end
  end

  describe "#send_empty_email" do
    let(:summarizer) { instance_double(OrderManagement::Subscriptions::Summarizer, record_order: true) }

    let(:changeset) { double(:changes) }
    let(:changes) { lambda { changeset } }

    before do
      allow(SubscriptionMailer).to receive(:empty_email) { mail_mock }
    end

    it "logs an issue and sends the email" do
      expect(summarizer).to receive(:record_issue).with(:empty, order).once

      subject.call

      expect(SubscriptionMailer).to have_received(:empty_email).with(order, changeset)
      expect(mail_mock).to have_received(:deliver_now)
    end
  end

  describe "#move_to_completion" do
    let(:order_cycle) { create(:simple_order_cycle) }
    let(:shop) { order_cycle.coordinator }
    let(:order) { create(:order, order_cycle: order_cycle, distributor: shop) }
    let(:ex) { create(:exchange, order_cycle: order_cycle, sender: shop, receiver: shop, incoming: false) }
    let(:variant1) { create(:variant, on_hand: 5) }
    let(:variant2) { create(:variant, on_hand: 5) }
    let(:variant3) { create(:variant, on_hand: 5) }
    let!(:line_item1) { create(:line_item, order: order, variant: variant1, quantity: 3) }
    let!(:line_item2) { create(:line_item, order: order, variant: variant2, quantity: 3) }
    let!(:line_item3) { create(:line_item, order: order, variant: variant3, quantity: 3) }

    context "and some items are not available from the order cycle" do
      before { [variant2, variant3].each { |v| ex.variants << v } }

      context "and insufficient stock exists to fulfil the order for some items" do
        before do
          variant1.update_attribute(:on_hand, 5)
          variant2.update_attribute(:on_hand, 2)
          variant3.update_attribute(:on_hand, 0)
        end

        context "and the order has been placed" do
          before do
            allow(order).to receive(:ensure_available_shipping_rates) { true }
            allow(order).to receive(:process_each_payment) { true }
          end

          it "removes the unavailable items from the shipment" do
            subject.move_to_completion
            expect(order.reload.shipment.manifest.size).to eq 1
          end
        end
      end
    end
  end
end
