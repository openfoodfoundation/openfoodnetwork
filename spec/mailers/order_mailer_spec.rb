# frozen_string_literal: true

require 'spec_helper'

describe Spree::OrderMailer do
  include OpenFoodNetwork::EmailHelper

  contect "original spree specs" do
    let(:order) do
      order = stub_model(Spree::Order)
      product = stub_model(Spree::Product, name: %{The "BEST" product})
      variant = stub_model(Spree::Variant, product: product)
      price = stub_model(Spree::Price, variant: variant, amount: 5.00)
      line_item = stub_model(Spree::LineItem, variant: variant, order: order, quantity: 1, price: 4.99)
      variant.stub(default_price: price)
      order.stub(line_items: [line_item])
      order
    end

    context ":from not set explicitly" do
      it "falls back to spree config" do
        message = Spree::OrderMailer.confirm_email_for_customer(order)
        message.from.should == [Spree::Config[:mails_from]]
      end
    end

    it "doesn't aggressively escape double quotes in confirmation body" do
      confirmation_email = Spree::OrderMailer.confirm_email_for_customer(order)
      confirmation_email.body.should_not include("&quot;")
    end

    it "confirm_email_for_customer accepts an order id as an alternative to an Order object" do
      Spree::Order.should_receive(:find).with(order.id).and_return(order)
      lambda {
        confirmation_email = Spree::OrderMailer.confirm_email_for_customer(order.id)
      }.should_not raise_error
    end

    it "cancel_email accepts an order id as an alternative to an Order object" do
      Spree::Order.should_receive(:find).with(order.id).and_return(order)
      lambda {
        cancel_email = Spree::OrderMailer.cancel_email(order.id)
      }.should_not raise_error
    end

    context "only shows eligible adjustments in emails" do
      before do
        order.adjustments.create(
          label: "Eligible Adjustment",
          amount: 10,
          eligible: true
        )

        order.adjustments.create!(
          label: "Ineligible Adjustment",
          amount: -10,
          eligible: false
        )
      end

      let!(:confirmation_email) { Spree::OrderMailer.confirm_email(order) }
      let!(:cancel_email) { Spree::OrderMailer.cancel_email(order) }

      specify do
        confirmation_email.body.should_not include("Ineligible Adjustment")
      end

      specify do
        cancel_email.body.should_not include("Ineligible Adjustment")
      end
    end

    context "displays unit costs from line item" do
      specify do
        confirmation_email = Spree::OrderMailer.confirm_email_for_customer(order)
        confirmation_email.body.should include("4.99")
        confirmation_email.body.should_not include("5.00")
      end

      specify do
        cancel_email = Spree::OrderMailer.cancel_email(order)
        cancel_email.body.should include("4.99")
        cancel_email.body.should_not include("5.00")
      end
    end

    context "emails must be translatable" do
      context "pt-BR locale" do
        before do
          pt_br_confirm_mail = { spree: { order_mailer: { confirm_email: { dear_customer: 'Caro Cliente,' } } } }
          pt_br_cancel_mail = { spree: { order_mailer: { cancel_email: { order_summary_canceled: 'Resumo da Pedido [CANCELADA]' } } } }
          I18n.backend.store_translations :'pt-BR', pt_br_confirm_mail
          I18n.backend.store_translations :'pt-BR', pt_br_cancel_mail
          I18n.locale = :'pt-BR'
        end

        after do
          I18n.locale = I18n.default_locale
        end

        context "confirm_email" do
          specify do
            confirmation_email = Spree::OrderMailer.confirm_email_for_customer(order)
            confirmation_email.body.should include("Caro Cliente,")
          end
        end

        context "cancel_email" do
          specify do
            cancel_email = Spree::OrderMailer.cancel_email(order)
            cancel_email.body.should include("Resumo da Pedido [CANCELADA]")
          end
        end
      end
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
