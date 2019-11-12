require 'spec_helper'

describe Spree::OrderMailer do
  include OpenFoodNetwork::EmailHelper

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
