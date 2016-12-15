require 'spec_helper'

describe Spree::OrderMailer do
  describe "order confimation" do
    after do
      ActionMailer::Base.deliveries.clear
    end

    before do
      ActionMailer::Base.delivery_method = :test
      ActionMailer::Base.perform_deliveries = true
      ActionMailer::Base.deliveries = []

      @bill_address = create(:address)
      @distributor_address = create(:address, :address1 => "distributor address", :city => 'The Shire', :zipcode => "1234")
      @distributor = create(:distributor_enterprise, :address => @distributor_address)
      product = create(:product)
      product_distribution = create(:product_distribution, :product => product, :distributor => @distributor)
      @shipping_instructions = "pick up on thursday please!"
      ship_address = create(:address, :address1 => "distributor address", :city => 'The Shire', :zipcode => "1234")
      @order1 = create(:order, :distributor => @distributor, :bill_address => @bill_address, ship_address: ship_address, :special_instructions => @shipping_instructions)
      ActionMailer::Base.deliveries = []
      Spree::MailMethod.create!(
        environment: Rails.env,
        preferred_mails_from: 'spree@example.com'
      )
    end

    describe "for customers" do
      it "should send an email to the customer when given an order" do
        Spree::OrderMailer.confirm_email_for_customer(@order1.id).deliver
        ActionMailer::Base.deliveries.count.should == 1
        ActionMailer::Base.deliveries.first.to.should == [@order1.email]
      end

      it "sets a reply-to of the enterprise email" do
        Spree::OrderMailer.confirm_email_for_customer(@order1.id).deliver
        ActionMailer::Base.deliveries.first.reply_to.should == [@distributor.email]
      end
    end

    describe "for shops" do
      it "sends an email to the shop owner when given an order" do
        Spree::OrderMailer.confirm_email_for_shop(@order1.id).deliver
        ActionMailer::Base.deliveries.count.should == 1
        ActionMailer::Base.deliveries.first.to.should == [@distributor.email]
      end

      it "sends an email even if a footer_email is given" do
        # Testing bug introduced by a9c37c162e1956028704fbdf74ce1c56c5b3ce7d
        ContentConfig.footer_email = "email@example.com"
        Spree::OrderMailer.confirm_email_for_shop(@order1.id).deliver
        ActionMailer::Base.deliveries.count.should == 1
      end
    end
  end

  describe "order placement for standing orders" do
    let(:standing_order) { create(:standing_order, with_items: true) }
    let(:proxy_order) { create(:proxy_order, standing_order: standing_order) }
    let!(:order) { proxy_order.initialise_order! }

    context "when changes have been made to the order" do
      let(:changes) { {} }

      before do
        changes[order.line_items.first.id] = 2
        expect do
          Spree::OrderMailer.standing_order_email(order.id, 'placement', changes).deliver
        end.to change{Spree::OrderMailer.deliveries.count}.by(1)
      end

      it "sends the email, which notifies the customer of changes made" do
        body = Spree::OrderMailer.deliveries.last.body.encoded
        expect(body).to include "This order was automatically created on your behalf."
        expect(body).to include "Unfortunately, not all products that you requested were available."
      end
    end

    context "and changes have not been made to the order" do
      before do
        expect do
          Spree::OrderMailer.standing_order_email(order.id, 'placement', {}).deliver
        end.to change{Spree::OrderMailer.deliveries.count}.by(1)
      end

      it "sends the email" do
        body = Spree::OrderMailer.deliveries.last.body.encoded
        expect(body).to include "This order was automatically created on your behalf."
        expect(body).to_not include "Unfortunately, not all products that you requested were available."
      end
    end
  end
end
