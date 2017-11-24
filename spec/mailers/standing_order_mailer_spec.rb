require 'spec_helper'

describe StandingOrderMailer do
  include ActionView::Helpers::SanitizeHelper

  let!(:mail_method) { create(:mail_method, preferred_mails_from: 'spree@example.com') }

  describe "order placement" do
    let(:standing_order) { create(:standing_order, with_items: true) }
    let(:proxy_order) { create(:proxy_order, standing_order: standing_order) }
    let!(:order) { proxy_order.initialise_order! }

    context "when changes have been made to the order" do
      let(:changes) { {} }

      before do
        changes[order.line_items.first.id] = 2
        expect do
          StandingOrderMailer.placement_email(order, changes).deliver
        end.to change{ StandingOrderMailer.deliveries.count }.by(1)
      end

      it "sends the email, which notifies the customer of changes made" do
        body = StandingOrderMailer.deliveries.last.body.encoded
        expect(body).to include "This order was automatically created for you."
        expect(body).to include "Unfortunately, not all products that you requested were available."
        expect(body).to include "href=\"#{spree.order_url(order)}\""
      end
    end

    context "and changes have not been made to the order" do
      before do
        expect do
          StandingOrderMailer.placement_email(order, {}).deliver
        end.to change{ StandingOrderMailer.deliveries.count }.by(1)
      end

      it "sends the email" do
        body = StandingOrderMailer.deliveries.last.body.encoded
        expect(body).to include "This order was automatically created for you."
        expect(body).to_not include "Unfortunately, not all products that you requested were available."
        expect(body).to include "href=\"#{spree.order_url(order)}\""
      end
    end
  end

  describe "order confirmation" do
    let(:standing_order) { create(:standing_order, with_items: true) }
    let(:proxy_order) { create(:proxy_order, standing_order: standing_order) }
    let!(:order) { proxy_order.initialise_order! }

    before do
      expect do
        StandingOrderMailer.confirmation_email(order).deliver
      end.to change{ StandingOrderMailer.deliveries.count }.by(1)
    end

    it "sends the email" do
      body = StandingOrderMailer.deliveries.last.body.encoded
      expect(body).to include "This order was automatically placed for you"
      expect(body).to include "href=\"#{spree.order_url(order)}\""
    end
  end

  describe "empty order notification" do
    let(:standing_order) { create(:standing_order, with_items: true) }
    let(:proxy_order) { create(:proxy_order, standing_order: standing_order) }
    let!(:order) { proxy_order.initialise_order! }

    before do
      expect do
        StandingOrderMailer.empty_email(order, {}).deliver
      end.to change{ StandingOrderMailer.deliveries.count }.by(1)
    end

    it "sends the email" do
      body = StandingOrderMailer.deliveries.last.body.encoded
      expect(body).to include "We tried to place a new order with"
      expect(body).to include "Unfortunately, none of products that you ordered were available"
    end
  end

  describe "failed payment notification" do
    let(:standing_order) { create(:standing_order, with_items: true) }
    let(:proxy_order) { create(:proxy_order, standing_order: standing_order) }
    let!(:order) { proxy_order.initialise_order! }

    before do
      order.errors.add(:base, "This is a payment failure error")

      expect do
        StandingOrderMailer.failed_payment_email(order).deliver
      end.to change{ StandingOrderMailer.deliveries.count }.by(1)
    end

    it "sends the email" do
      body = strip_tags(StandingOrderMailer.deliveries.last.body.encoded)
      expect(body).to include I18n.t("email_so_failed_payment_intro_html")
      explainer = I18n.t("email_so_failed_payment_explainer_html", distributor: standing_order.shop.name)
      expect(body).to include strip_tags(explainer)
      details = I18n.t("email_so_failed_payment_details_html", distributor: standing_order.shop.name)
      expect(body).to include strip_tags(details)
      expect(body).to include "This is a payment failure error"
    end
  end

  describe "order placement summary" do
    let!(:shop) { create(:enterprise) }
    let!(:summary) { double(:summary, shop_id: shop.id) }
    let(:body) { strip_tags(StandingOrderMailer.deliveries.last.body.encoded) }
    let(:scope) { "standing_order_mailer" }

    before { allow(summary).to receive(:unrecorded_ids) { [] } }

    context "when no issues were encountered while processing standing orders" do
      before do
        allow(summary).to receive(:order_count) { 37 }
        allow(summary).to receive(:issue_count) { 0 }
        allow(summary).to receive(:issues) { {} }
        StandingOrderMailer.placement_summary_email(summary).deliver
      end

      it "sends the email, which notifies the enterprise that all orders were successfully processed" do
        expect(body).to include I18n.t("#{scope}.placement_summary_email.intro")
        expect(body).to include I18n.t("#{scope}.summary_overview.total", count: 37)
        expect(body).to include I18n.t("#{scope}.summary_overview.success_all")
        expect(body).to_not include I18n.t("#{scope}.summary_overview.issues")
      end
    end

    context "when some issues were encountered while processing standing orders" do
      let(:order1) { double(:order, id: 1, number: "R123456", to_s: "R123456") }
      let(:order2) { double(:order, id: 2, number: "R654321", to_s: "R654321") }

      before do
        allow(summary).to receive(:order_count) { 37 }
        allow(summary).to receive(:success_count) { 35 }
        allow(summary).to receive(:issue_count) { 2 }
        allow(summary).to receive(:issues) { { processing: { 1 => "Some Error Message", 2 => nil } } }
        allow(summary).to receive(:orders_affected_by) { [order1, order2] }
      end

      context "when no unrecorded issues are present" do
        it "sends the email, which notifies the enterprise that some issues were encountered" do
          StandingOrderMailer.placement_summary_email(summary).deliver
          expect(body).to include I18n.t("#{scope}.placement_summary_email.intro")
          expect(body).to include I18n.t("#{scope}.summary_overview.total", count: 37)
          expect(body).to include I18n.t("#{scope}.summary_overview.success_some", count: 35)
          expect(body).to include I18n.t("#{scope}.summary_overview.issues")
          expect(body).to include I18n.t("#{scope}.summary_detail.processing.title", count: 2)
          expect(body).to include I18n.t("#{scope}.summary_detail.processing.explainer")

          # Lists orders for which an error was encountered
          expect(body).to include order1.number
          expect(body).to include order2.number

          # Reports error messages provided by the summary, or default if none provided
          expect(body).to include "Some Error Message"
          expect(body).to include I18n.t("#{scope}.summary_detail.no_message_provided")
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
          StandingOrderMailer.placement_summary_email(summary).deliver
          expect(body).to include I18n.t("#{scope}.summary_detail.processing.title", count: 2)
          expect(body).to include I18n.t("#{scope}.summary_detail.processing.explainer")
          expect(body).to include I18n.t("#{scope}.summary_detail.other.title", count: 2)
          expect(body).to include I18n.t("#{scope}.summary_detail.other.explainer")

          # Lists orders for which no error or success was recorded
          expect(body).to include order3.number
          expect(body).to include order4.number
        end
      end
    end

    context "when no standing orders were processed successfully" do
      let(:order1) { double(:order, id: 1, number: "R123456", to_s: "R123456") }
      let(:order2) { double(:order, id: 2, number: "R654321", to_s: "R654321") }

      before do
        allow(summary).to receive(:order_count) { 2 }
        allow(summary).to receive(:success_count) { 0 }
        allow(summary).to receive(:issue_count) { 2 }
        allow(summary).to receive(:issues) { { changes: { 1 => nil, 2 => nil } } }
        allow(summary).to receive(:orders_affected_by) { [order1, order2] }
        StandingOrderMailer.placement_summary_email(summary).deliver
      end

      it "sends the email, which notifies the enterprise that some issues were encountered" do
        expect(body).to include I18n.t("#{scope}.placement_summary_email.intro")
        expect(body).to include I18n.t("#{scope}.summary_overview.total", count: 2)
        expect(body).to include I18n.t("#{scope}.summary_overview.success_zero")
        expect(body).to include I18n.t("#{scope}.summary_overview.issues")
        expect(body).to include I18n.t("#{scope}.summary_detail.changes.title", count: 2)
        expect(body).to include I18n.t("#{scope}.summary_detail.changes.explainer")

        # Lists orders for which an error was encountered
        expect(body).to include order1.number
        expect(body).to include order2.number

        # No error messages reported when non provided
        expect(body).to_not include I18n.t("#{scope}.summary_detail.no_message_provided")
      end
    end
  end

  describe "order confirmation summary" do
    let!(:shop) { create(:enterprise) }
    let!(:summary) { double(:summary, shop_id: shop.id) }
    let(:body) { strip_tags(StandingOrderMailer.deliveries.last.body.encoded) }
    let(:scope) { "standing_order_mailer" }

    before { allow(summary).to receive(:unrecorded_ids) { [] } }

    context "when no issues were encountered while processing standing orders" do
      before do
        allow(summary).to receive(:order_count) { 37 }
        allow(summary).to receive(:issue_count) { 0 }
        allow(summary).to receive(:issues) { {} }
        StandingOrderMailer.confirmation_summary_email(summary).deliver
      end

      it "sends the email, which notifies the enterprise that all orders were successfully processed" do
        expect(body).to include I18n.t("#{scope}.confirmation_summary_email.intro")
        expect(body).to include I18n.t("#{scope}.summary_overview.total", count: 37)
        expect(body).to include I18n.t("#{scope}.summary_overview.success_all")
        expect(body).to_not include I18n.t("#{scope}.summary_overview.issues")
      end
    end

    context "when some issues were encountered while processing standing orders" do
      let(:order1) { double(:order, id: 1, number: "R123456", to_s: "R123456") }
      let(:order2) { double(:order, id: 2, number: "R654321", to_s: "R654321") }

      before do
        allow(summary).to receive(:order_count) { 37 }
        allow(summary).to receive(:success_count) { 35 }
        allow(summary).to receive(:issue_count) { 2 }
        allow(summary).to receive(:issues) { { failed_payment: { 1 => "Some Error Message", 2 => nil } } }
        allow(summary).to receive(:orders_affected_by) { [order1, order2] }
      end

      context "when no unrecorded issues are present" do
        it "sends the email, which notifies the enterprise that some issues were encountered" do
          StandingOrderMailer.confirmation_summary_email(summary).deliver
          expect(body).to include I18n.t("#{scope}.confirmation_summary_email.intro")
          expect(body).to include I18n.t("#{scope}.summary_overview.total", count: 37)
          expect(body).to include I18n.t("#{scope}.summary_overview.success_some", count: 35)
          expect(body).to include I18n.t("#{scope}.summary_overview.issues")
          expect(body).to include I18n.t("#{scope}.summary_detail.failed_payment.title", count: 2)
          expect(body).to include I18n.t("#{scope}.summary_detail.failed_payment.explainer")

          # Lists orders for which an error was encountered
          expect(body).to include order1.number
          expect(body).to include order2.number

          # Reports error messages provided by the summary, or default if none provided
          expect(body).to include "Some Error Message"
          expect(body).to include I18n.t("#{scope}.summary_detail.no_message_provided")
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
          StandingOrderMailer.confirmation_summary_email(summary).deliver
          expect(body).to include I18n.t("#{scope}.summary_detail.failed_payment.title", count: 2)
          expect(body).to include I18n.t("#{scope}.summary_detail.failed_payment.explainer")
          expect(body).to include I18n.t("#{scope}.summary_detail.other.title", count: 2)
          expect(body).to include I18n.t("#{scope}.summary_detail.other.explainer")

          # Lists orders for which no error or success was recorded
          expect(body).to include order3.number
          expect(body).to include order4.number
        end
      end
    end

    context "when no standing orders were processed successfully" do
      let(:order1) { double(:order, id: 1, number: "R123456", to_s: "R123456") }
      let(:order2) { double(:order, id: 2, number: "R654321", to_s: "R654321") }

      before do
        allow(summary).to receive(:order_count) { 2 }
        allow(summary).to receive(:success_count) { 0 }
        allow(summary).to receive(:issue_count) { 2 }
        allow(summary).to receive(:issues) { { changes: { 1 => nil, 2 => nil } } }
        allow(summary).to receive(:orders_affected_by) { [order1, order2] }
        StandingOrderMailer.confirmation_summary_email(summary).deliver
      end

      it "sends the email, which notifies the enterprise that some issues were encountered" do
        expect(body).to include I18n.t("#{scope}.confirmation_summary_email.intro")
        expect(body).to include I18n.t("#{scope}.summary_overview.total", count: 2)
        expect(body).to include I18n.t("#{scope}.summary_overview.success_zero")
        expect(body).to include I18n.t("#{scope}.summary_overview.issues")
        expect(body).to include I18n.t("#{scope}.summary_detail.changes.title", count: 2)
        expect(body).to include I18n.t("#{scope}.summary_detail.changes.explainer")

        # Lists orders for which an error was encountered
        expect(body).to include order1.number
        expect(body).to include order2.number

        # No error messages reported when non provided
        expect(body).to_not include I18n.t("#{scope}.summary_detail.no_message_provided")
      end
    end
  end
end
