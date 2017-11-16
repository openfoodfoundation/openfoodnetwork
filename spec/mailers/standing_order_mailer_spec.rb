require 'spec_helper'

describe StandingOrderMailer do
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
        end.to change{StandingOrderMailer.deliveries.count}.by(1)
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
        end.to change{StandingOrderMailer.deliveries.count}.by(1)
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
      end.to change{StandingOrderMailer.deliveries.count}.by(1)
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
      end.to change{StandingOrderMailer.deliveries.count}.by(1)
    end

    it "sends the email" do
      body = StandingOrderMailer.deliveries.last.body.encoded
      expect(body).to include "We tried to place a new order with"
      expect(body).to include "Unfortunately, none of products that you ordered were available"
    end
  end
end
