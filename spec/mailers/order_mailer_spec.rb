# frozen_string_literal: true

require 'spec_helper'

describe Spree::OrderMailer do
  include OpenFoodNetwork::EmailHelper

  context "basic behaviour" do
    let(:order) { build(:order_with_totals_and_distribution) }

    context ":from not set explicitly" do
      it "falls back to spree config" do
        message = Spree::OrderMailer.confirm_email_for_customer(order)
        expect(message.from).to eq [Spree::Config[:mails_from]]
      end
    end

    it "doesn't aggressively escape double quotes in confirmation body" do
      confirmation_email = Spree::OrderMailer.confirm_email_for_customer(order)
      expect(confirmation_email.body).to_not include("&quot;")
    end

    it "confirm_email_for_customer accepts an order id as an alternative to an Order object" do
      expect(Spree::Order).to receive(:find).with(order.id).and_return(order)
      expect {
        Spree::OrderMailer.confirm_email_for_customer(order.id).deliver
      }.to_not raise_error
    end

    it "cancel_email accepts an order id as an alternative to an Order object" do
      expect(Spree::Order).to receive(:find).with(order.id).and_return(order)
      expect {
        Spree::OrderMailer.cancel_email(order.id).deliver
      }.to_not raise_error
    end
  end

  context "only shows eligible adjustments in emails" do
    let(:order) { create(:order_with_totals_and_distribution) }

    before do
      order.adjustments.create(
        label: "Eligible Adjustment",
        amount: 10,
        eligible: true
      )

      order.adjustments.create!(
        label: "Ineligible Adjustment",
        amount: 0,
      )
    end

    let!(:confirmation_email) { Spree::OrderMailer.confirm_email_for_customer(order) }
    let!(:cancel_email) { Spree::OrderMailer.cancel_email(order) }

    specify do
      expect(confirmation_email.body).to_not include("Ineligible Adjustment")
    end

    specify do
      expect(cancel_email.body).to_not include("Ineligible Adjustment")
    end
  end

  context "displays line item price" do
    let(:order) { create(:order_with_totals_and_distribution) }

    specify do
      confirmation_email = Spree::OrderMailer.confirm_email_for_customer(order)
      expect(confirmation_email.body).to include("3.00")
    end

    specify do
      cancel_email = Spree::OrderMailer.cancel_email(order)
      expect(cancel_email.body).to include("3.00")
    end
  end

  describe "order confimation" do
    let(:bill_address) { create(:address) }
    let(:distributor_address) { create(:address, address1: "distributor address", city: 'The Shire', zipcode: "1234") }
    let(:distributor) { create(:distributor_enterprise, address: distributor_address) }
    let(:shipping_instructions) { "pick up on thursday please!" }
    let(:ship_address) { create(:address, address1: "distributor address", city: 'The Shire', zipcode: "1234") }
    let(:order) {
      create(:order_with_line_items, distributor: distributor, bill_address: bill_address, ship_address: ship_address,
                                     special_instructions: shipping_instructions)
    }

    after do
      ActionMailer::Base.deliveries.clear
    end

    before do
      setup_email
      ActionMailer::Base.delivery_method = :test
      ActionMailer::Base.perform_deliveries = true
      ActionMailer::Base.deliveries = []
    end

    describe "for customers" do
      it "should send an email to the customer when given an order" do
        Spree::OrderMailer.confirm_email_for_customer(order.id).deliver
        expect(ActionMailer::Base.deliveries.count).to eq(1)
        expect(ActionMailer::Base.deliveries.first.to).to eq([order.email])
      end

      it "should include SKUs" do
        mail = Spree::OrderMailer.confirm_email_for_customer(order.id)

        expect(mail.body.encoded).to include "SKU"
        expect(mail.body.encoded).to include order.line_items.first.variant.sku
      end

      it "sets a reply-to of the enterprise email" do
        Spree::OrderMailer.confirm_email_for_customer(order.id).deliver
        expect(ActionMailer::Base.deliveries.first.reply_to).to eq([distributor.contact.email])
      end
    end

    describe "for shops" do
      it "sends an email to the shop owner when given an order" do
        Spree::OrderMailer.confirm_email_for_shop(order.id).deliver
        expect(ActionMailer::Base.deliveries.count).to eq(1)
        expect(ActionMailer::Base.deliveries.first.to).to eq([distributor.contact.email])
      end

      it "sends an email even if a footer_email is given" do
        # Testing bug introduced by a9c37c162e1956028704fbdf74ce1c56c5b3ce7d
        ContentConfig.footer_email = "email@example.com"
        Spree::OrderMailer.confirm_email_for_shop(order.id).deliver
        expect(ActionMailer::Base.deliveries.count).to eq(1)
      end
    end
  end
end
