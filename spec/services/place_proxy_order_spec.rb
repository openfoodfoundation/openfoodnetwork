# frozen_string_literal: true

require 'spec_helper'

describe PlaceProxyOrder do
  include ActiveSupport::Testing::TimeHelpers

  subject { described_class.new(proxy_order, summarizer, logger, stock_changes_loader) }

  let(:proxy_order) { create(:proxy_order, order: order) }
  let(:order) { build(:order) }
  let(:summarizer) { instance_double(OrderManagement::Subscriptions::Summarizer) }
  let(:logger) { instance_double(JobLogger.logger.class, info: true) }

  let(:mail_mock) { double(:mailer_mock, deliver_now: true) }

  describe "#call" do
    let!(:subscription) { create(:subscription, with_items: true) }
    let!(:proxy_order) { create(:proxy_order, subscription: subscription, order: order) }

    let(:stock_changes_loader) { lambda { {} } }
    let(:summarizer) { instance_double(OrderManagement::Subscriptions::Summarizer, record_order: true, record_issue: true) }

    before do
      allow(SubscriptionMailer).to receive(:empty_email) { mail_mock }
    end

    it "marks placeable proxy_orders as processed by setting placed_at" do
      freeze_time do
        expect { subject.call }.to change { proxy_order.reload.placed_at }
        expect(proxy_order.placed_at).to eq(Time.zone.now)
      end
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
      let(:stock_changes_loader) { lambda { {} } }

      it "logs a success and sends the email" do
        expect(summarizer).to receive(:record_success).with(order).once

        subject.call

        expect(SubscriptionMailer).to have_received(:placement_email)
        expect(mail_mock).to have_received(:deliver_now)
      end
    end

    context "when changes are present" do
      let(:changeset) { double(:changes) }
      let(:stock_changes_loader) { lambda { changeset } }

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
    let(:stock_changes_loader) { lambda { changeset } }

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
end
