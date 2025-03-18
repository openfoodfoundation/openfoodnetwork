# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SubscriptionMailer, type: :mailer do
  include ActionView::Helpers::SanitizeHelper

  describe '#placement_email' do
    subject(:email) { SubscriptionMailer.placement_email(order, changes) }
    let(:changes) { {} }

    let(:shop) { create(:enterprise) }
    let(:customer) { create(:customer, enterprise: shop) }
    let(:subscription) { create(:subscription, shop:, customer:, with_items: true) }
    let(:proxy_order) { create(:proxy_order, subscription:) }
    let!(:order) { proxy_order.initialise_order! }

    context "when changes have been made to the order" do
      before { changes[order.line_items.first.id] = 2 }

      it "sends the email, which notifies the customer of changes made" do
        expect { email.deliver_now }.to change { SubscriptionMailer.deliveries.count }.by(1)

        body = SubscriptionMailer.deliveries.last.body.encoded

        expect(body).to include "This order was automatically created for you."
        expect(body).to include "Unfortunately, not all products that you requested were available."
      end
    end

    context "and changes have not been made to the order" do
      it "sends the email" do
        expect { email.deliver_now }.to change { SubscriptionMailer.deliveries.count }.by(1)

        body = SubscriptionMailer.deliveries.last.body.encoded

        expect(body).to include "This order was automatically created for you."
        expect(body).not_to include "Unfortunately, not all products " \
                                    "that you requested were available."
      end
    end

    describe "linking to order page" do
      let(:shop) { create(:enterprise, allow_order_changes: true) }

      let(:content) { Capybara::Node::Simple.new(body) }
      let(:body) { SubscriptionMailer.deliveries.last.body.encoded }

      before { email.deliver_now }

      context "when the customer has a user account" do
        let(:customer) { create(:customer, enterprise: shop) }

        it "provides link to make changes" do
          expect(content).to have_link "make changes", href: order_url(order)
          expect(content).not_to have_link "view details of this order", href: order_url(order)
        end

        context "when the distributor does not allow changes to the order" do
          let(:shop) { create(:enterprise, allow_order_changes: false) }

          it "provides link to view details" do
            expect(content).not_to have_link "make changes", href: order_url(order)
            expect(content).to have_link "view details of this order", href: order_url(order)
          end
        end
      end

      context "when the customer has no user account" do
        let(:customer) { create(:customer, enterprise: shop, user: nil) }

        it "does not provide link" do
          expect(body).not_to match order_url(order)
        end

        context "when the distributor does not allow changes to the order" do
          let(:shop) { create(:enterprise, allow_order_changes: false) }

          it "does not provide link" do
            expect(body).not_to match order_url(order)
          end
        end
      end
    end

    context 'when the order has outstanding balance' do
      before { allow(order).to receive(:new_outstanding_balance) { 123 } }

      it 'renders the amount as money' do
        expect(email.body).to include('$123')
      end
    end

    context 'when the order has no outstanding balance' do
      before { allow(order).to receive(:new_outstanding_balance) { 0 } }

      it 'displays the payment status' do
        expect(email.body).to include('NOT PAID')
      end
    end
  end

  describe '#confirmation_email' do
    subject(:email) { SubscriptionMailer.confirmation_email(order) }

    let(:customer) { create(:customer) }
    let(:subscription) { create(:subscription, customer:, with_items: true) }
    let(:proxy_order) { create(:proxy_order, subscription:) }
    let!(:order) { proxy_order.initialise_order! }
    let(:user) { order.user }

    it "sends the email" do
      expect { email.deliver_now }.to change{ SubscriptionMailer.deliveries.count }.by(1)

      body = SubscriptionMailer.deliveries.last.body.encoded
      expect(body).to include "This order was automatically placed for you"
    end

    it "display the OFN header by default" do
      expect(email.body).to include(ContentConfig.url_for(:logo))
    end

    describe "linking to order page" do
      let(:order_link_href) { "href=\"#{order_url(order)}\"" }

      context "when the customer has a user account" do
        let(:customer) { create(:customer) }

        it "provides link to view details" do
          expect(email.body.encoded).to include(order_url(order))
        end
      end

      context "when the customer has no user account" do
        let(:customer) { create(:customer, user: nil) }

        it "does not provide link" do
          expect(email.body).not_to match /#{order_link_href}/
        end
      end
    end

    context 'when the order has outstanding balance' do
      before { allow(order).to receive(:new_outstanding_balance) { 123 } }

      it 'renders the amount as money' do
        expect(email.body).to include('$123')
      end
    end

    context 'when the order has no outstanding balance' do
      before { allow(order).to receive(:new_outstanding_balance) { 0 } }

      it 'displays the payment status' do
        expect(email.body).to include('NOT PAID')
      end
    end

    context 'when hide OFN navigation is enabled for the distributor of the order' do
      before do
        allow(order.distributor).to receive(:hide_ofn_navigation).and_return(true)
      end

      it 'does not display the OFN navigation' do
        expect(email.body).not_to include(ContentConfig.url_for(:logo))
      end
    end
  end

  describe "empty order notification" do
    let(:subscription) { create(:subscription, with_items: true) }
    let(:proxy_order) { create(:proxy_order, subscription:) }
    let!(:order) { proxy_order.initialise_order! }

    before do
      expect do
        SubscriptionMailer.empty_email(order, {}).deliver_now
      end.to change{ SubscriptionMailer.deliveries.count }.by(1)
    end

    it "sends the email" do
      body = SubscriptionMailer.deliveries.last.body.encoded
      expect(body).to include "We tried to place a new order with"
      expect(body).to include "Unfortunately, none of products that you ordered were available"
    end
  end

  describe "failed payment notification" do
    let(:customer) { create(:customer) }
    let(:subscription) { create(:subscription, customer:, with_items: true) }
    let(:proxy_order) { create(:proxy_order, subscription:) }
    let!(:order) { proxy_order.initialise_order! }

    before do
      order.errors.add(:base, "This is a payment failure error")

      expect do
        SubscriptionMailer.failed_payment_email(order).deliver_now
      end.to change{ SubscriptionMailer.deliveries.count }.by(1)
    end

    it "sends the email" do
      body = strip_tags(SubscriptionMailer.deliveries.last.body.encoded)
      expect(body).to include 'We tried to process a payment, but had some problems...'
      email_so_failed_payment_explainer_html = "The payment for your subscription with <strong>%s" \
                                               "</strong> failed because of a problem with your " \
                                               "credit card. <strong>%s</strong> has been " \
                                               "notified of this failed payment."
      explainer = email_so_failed_payment_explainer_html % ([subscription.shop.name] * 2)
      expect(body).to include strip_tags(explainer)
      details = 'Here are the details of the failure provided by the payment gateway:'
      expect(body).to include strip_tags(details)
      expect(body).to include "This is a payment failure error"
    end

    describe "linking to order page" do
      let(:order_link_href) { "href=\"#{order_url(order)}\"" }

      let(:email) { SubscriptionMailer.deliveries.last }
      let(:body) { email.body.encoded }

      context "when the customer has a user account" do
        let(:customer) { create(:customer) }

        it "provides link to view details" do
          expect(body).to match /#{order_link_href}/
        end
      end

      context "when the customer has no user account" do
        let(:customer) { create(:customer, user: nil) }

        it "does not provide link" do
          expect(body).not_to match /#{order_link_href}/
        end
      end
    end
  end

  describe "order placement summary" do
    let!(:shop) { create(:enterprise, :with_logo_image) }
    let!(:summary) { double(:summary, shop_id: shop.id) }
    let(:body) { strip_tags(SubscriptionMailer.deliveries.last.body.encoded) }
    let(:scope) { "subscription_mailer" }

    before do
      allow(summary).to receive(:unrecorded_ids) { [] }
      allow(summary).to receive(:subscription_issues) { [] }
    end

    context "when no issues were encountered while processing subscriptions" do
      before do
        allow(summary).to receive(:order_count) { 37 }
        allow(summary).to receive(:issue_count) { 0 }
        allow(summary).to receive(:issues) { {} }
      end

      it "sends the email, which notifies the enterprise that all orders " \
         "were successfully processed" do
        SubscriptionMailer.placement_summary_email(summary).deliver_now

        expect(body).to include("Below is a summary of the subscription orders " \
                                "that have just been placed for %s." % shop.name)
        expect(body).to include("A total of %d subscriptions were marked " \
                                "for automatic processing." % 37)
        expect(body).to include 'All were processed successfully.'
        expect(body).not_to include 'Details of the issues encountered are provided below.'
      end

      it "renders the shop's logo" do
        SubscriptionMailer.placement_summary_email(summary).deliver_now
        expect(SubscriptionMailer.deliveries.last.body).to include "logo.png"
      end
    end

    context "when some issues were encountered while processing subscriptions" do
      let(:order1) { double(:order, id: 1, number: "R123456", to_s: "R123456") }
      let(:order2) { double(:order, id: 2, number: "R654321", to_s: "R654321") }

      before do
        allow(summary).to receive(:order_count) { 37 }
        allow(summary).to receive(:success_count) { 35 }
        allow(summary).to receive(:issue_count) { 2 }
        allow(summary).to receive(:issues) {
                            { processing: { 1 => "Some Error Message", 2 => nil } }
                          }
        allow(summary).to receive(:orders_affected_by) { [order1, order2] }
      end

      context "when no unrecorded issues are present" do
        it "sends the email, which notifies the enterprise that some issues were encountered" do
          SubscriptionMailer.placement_summary_email(summary).deliver_now
          expect(body).to include("Below is a summary of the subscription orders " \
                                  "that have just been placed for %s." % shop.name)
          expect(body).to include("A total of %d subscriptions were marked " \
                                  "for automatic processing." % 37)
          expect(body).to include('Of these, %d were processed successfully.' % 35)
          expect(body).to include 'Details of the issues encountered are provided below.'
          expect(body).to include('Error Encountered (%d orders)' % 2)
          expect(body).to include 'Automatic processing of these orders failed due to an error. ' \
                                  'The error has been listed where possible.'

          # Lists orders for which an error was encountered
          expect(body).to include order1.number
          expect(body).to include order2.number

          # Reports error messages provided by the summary, or default if none provided
          expect(body).to include "Some Error Message"
          expect(body).to include 'No error message provided'
        end
      end

      context "when some undocumented orders are present" do
        let(:order3) { double(:order, id: 3, number: "R333333", to_s: "R333333") }
        let(:order4) { double(:order, id: 4, number: "R444444", to_s: "R444444") }

        before do
          allow(summary).to receive(:unrecorded_ids) { [3, 4] }
        end

        it "sends the email, which notifies the enterprise that some issues were encountered" do
          expect(summary).to receive(:orders_affected_by).with(:other) { [order3, order4] }
          SubscriptionMailer.placement_summary_email(summary).deliver_now
          expect(body).to include("Error Encountered (%d orders)" % 2)
          expect(body).to include 'Automatic processing of these orders failed due to an error. ' \
                                  'The error has been listed where possible.'
          expect(body).to include("Other Failure (%d orders)" % 2)
          expect(body).to include 'Automatic processing of these orders failed ' \
                                  'for an unknown reason. This should not occur, ' \
                                  'please contact us if you are seeing this.'

          # Lists orders for which no error or success was recorded
          expect(body).to include order3.number
          expect(body).to include order4.number
        end
      end
    end

    context "when no subscriptions were processed successfully" do
      let(:order1) { double(:order, id: 1, number: "R123456", to_s: "R123456") }
      let(:order2) { double(:order, id: 2, number: "R654321", to_s: "R654321") }

      before do
        allow(summary).to receive(:order_count) { 2 }
        allow(summary).to receive(:success_count) { 0 }
        allow(summary).to receive(:issue_count) { 2 }
        allow(summary).to receive(:issues) { { changes: { 1 => nil, 2 => nil } } }
        allow(summary).to receive(:orders_affected_by) { [order1, order2] }
        SubscriptionMailer.placement_summary_email(summary).deliver_now
      end

      it "sends the email, which notifies the enterprise that some issues were encountered" do
        expect(body).to include("Below is a summary of the subscription orders " \
                                "that have just been placed for %s" % shop.name)
        expect(body).to include("A total of %d subscriptions were marked " \
                                "for automatic processing." % 2)
        expect(body).to include 'Of these, none were processed successfully.'
        expect(body).to include 'Details of the issues encountered are provided below.'
        expect(body).to include("Insufficient Stock (%d orders)" % 2)
        expect(body).to include 'These orders were processed but insufficient stock ' \
                                'was available for some requested items'

        # Lists orders for which an error was encountered
        expect(body).to include order1.number
        expect(body).to include order2.number

        # No error messages reported when non provided
        expect(body).not_to include 'No error message provided'
      end
    end
  end

  describe "order confirmation summary" do
    let!(:shop) { create(:enterprise) }
    let!(:summary) { double(:summary, shop_id: shop.id) }
    let(:body) { strip_tags(SubscriptionMailer.deliveries.last.body.encoded) }
    let(:scope) { "subscription_mailer" }

    before do
      allow(summary).to receive(:unrecorded_ids) { [] }
      allow(summary).to receive(:subscription_issues) { [] }
    end

    context "when no issues were encountered while processing subscriptions" do
      before do
        allow(summary).to receive(:order_count) { 37 }
        allow(summary).to receive(:issue_count) { 0 }
        allow(summary).to receive(:issues) { {} }
        SubscriptionMailer.confirmation_summary_email(summary).deliver_now
      end

      it "sends the email, which notifies the enterprise " \
         "that all orders were successfully processed" do
        expect(body).to include("Below is a summary of the subscription orders " \
                                "that have just been finalised for %s." % shop.name)
        expect(body).to include("A total of %d subscriptions were marked " \
                                "for automatic processing." % 37)
        expect(body).to include 'All were processed successfully.'
        expect(body).not_to include 'Details of the issues encountered are provided below.'
      end
    end

    context "when some issues were encountered while processing subscriptions" do
      let(:order1) { double(:order, id: 1, number: "R123456", to_s: "R123456") }
      let(:order2) { double(:order, id: 2, number: "R654321", to_s: "R654321") }

      before do
        allow(summary).to receive(:order_count) { 37 }
        allow(summary).to receive(:success_count) { 35 }
        allow(summary).to receive(:issue_count) { 2 }
        allow(summary).to receive(:issues) {
                            { failed_payment: { 1 => "Some Error Message", 2 => nil } }
                          }
        allow(summary).to receive(:orders_affected_by) { [order1, order2] }
      end

      context "when no unrecorded issues are present" do
        it "sends the email, which notifies the enterprise that some issues were encountered" do
          SubscriptionMailer.confirmation_summary_email(summary).deliver_now
          expect(body).to include("Below is a summary of the subscription orders " \
                                  "that have just been finalised for %s." % shop.name)
          expect(body).to include("A total of %d subscriptions were marked " \
                                  "for automatic processing." % 37)
          expect(body).to include("Of these, %d were processed successfully." % 35)
          expect(body).to include 'Details of the issues encountered are provided below.'
          expect(body).to include("Failed Payment (%d orders)" % 2)
          expect(body).to include 'Automatic processing of payment for these orders failed ' \
                                  'due to an error. The error has been listed where possible.'

          # Lists orders for which an error was encountered
          expect(body).to include order1.number
          expect(body).to include order2.number

          # Reports error messages provided by the summary, or default if none provided
          expect(body).to include "Some Error Message"
          expect(body).to include 'No error message provided'
        end
      end

      context "when some undocumented orders are present" do
        let(:order3) { double(:order, id: 3, number: "R333333", to_s: "R333333") }
        let(:order4) { double(:order, id: 4, number: "R444444", to_s: "R444444") }

        before do
          allow(summary).to receive(:unrecorded_ids) { [3, 4] }
        end

        it "sends the email, which notifies the enterprise that some issues were encountered" do
          expect(summary).to receive(:orders_affected_by).with(:other) { [order3, order4] }
          SubscriptionMailer.confirmation_summary_email(summary).deliver_now
          expect(body).to include("Failed Payment (%d orders)" % 2)
          expect(body).to include 'Automatic processing of payment for these orders failed ' \
                                  'due to an error. The error has been listed where possible.'
          expect(body).to include("Other Failure (%d orders)" % 2)
          expect(body).to include 'Automatic processing of these orders failed ' \
                                  'for an unknown reason. This should not occur, ' \
                                  'please contact us if you are seeing this.'

          # Lists orders for which no error or success was recorded
          expect(body).to include order3.number
          expect(body).to include order4.number
        end
      end
    end

    context "when no subscriptions were processed successfully" do
      let(:order1) { double(:order, id: 1, number: "R123456", to_s: "R123456") }
      let(:order2) { double(:order, id: 2, number: "R654321", to_s: "R654321") }

      before do
        allow(summary).to receive(:order_count) { 2 }
        allow(summary).to receive(:success_count) { 0 }
        allow(summary).to receive(:issue_count) { 2 }
        allow(summary).to receive(:issues) { { changes: { 1 => nil, 2 => nil } } }
        allow(summary).to receive(:orders_affected_by) { [order1, order2] }
        SubscriptionMailer.confirmation_summary_email(summary).deliver_now
      end

      it "sends the email, which notifies the enterprise that some issues were encountered" do
        expect(body).to include("Below is a summary of the subscription orders that " \
                                "have just been finalised for %s." % shop.name)
        expect(body).to include("A total of %d subscriptions were marked " \
                                "for automatic processing." % 2)
        expect(body).to include 'Of these, none were processed successfully.'
        expect(body).to include 'Details of the issues encountered are provided below.'
        expect(body).to include("Insufficient Stock (%d orders)" % 2)
        expect(body).to include 'These orders were processed but insufficient stock ' \
                                'was available for some requested items'

        # Lists orders for which an error was encountered
        expect(body).to include order1.number
        expect(body).to include order2.number

        # No error messages reported when non provided
        expect(body).not_to include 'No error message provided'
      end
    end
  end
end
