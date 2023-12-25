# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Spree::OrderMailer do
  describe '#confirm_email_for_customer' do
    subject(:email) { described_class.confirm_email_for_customer(order) }

    let(:order) { build(:order_with_totals_and_distribution) }

    it 'renders the shared/_payment.html.haml partial' do
      expect(email.body).to include('Payment summary')
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

    context "when :from is not set explicitly" do
      it "falls back to spree config" do
        expect(email.from).to eq [Spree::Config[:mails_from]]
      end
    end

    it "doesn't aggressively escape double quotes body" do
      expect(email.body).not_to include("&quot;")
    end

    it "accepts an order id as an alternative to an Order object" do
      expect(Spree::Order).to receive(:find).with(order.id).and_return(order)
      expect {
        described_class.confirm_email_for_customer(order.id).deliver_now
      }.not_to raise_error
    end

    it "display the OFN header by default" do
      expect(email.body).to include(ContentConfig.url_for(:logo))
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

  describe '#confirm_email_for_shop' do
    subject(:email) { described_class.confirm_email_for_shop(order) }

    let(:order) { build(:order_with_totals_and_distribution) }

    it 'renders the shared/_payment.html.haml partial' do
      expect(email.body).to include('Payment summary')
    end

    context 'when the order has outstanding balance' do
      before { allow(order).to receive(:new_outstanding_balance) { 123 } }

      it 'renders the amount as money' do
        expect(email.body).to include('$123')
      end
    end

    context 'when the order has no outstanding balance' do
      it 'displays the payment status' do
        expect(email.body).to include('NOT PAID')
      end
    end
  end

  context "basic behaviour" do
    let(:order) { build(:order_with_totals_and_distribution) }

    it "cancel_email accepts an order id as an alternative to an Order object" do
      expect(Spree::Order).to receive(:find).with(order.id).and_return(order)
      expect {
        Spree::OrderMailer.cancel_email(order.id).deliver_now
      }.not_to raise_error
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
      expect(confirmation_email.body).not_to include("Ineligible Adjustment")
    end

    specify do
      expect(cancel_email.body).not_to include("Ineligible Adjustment")
    end
  end

  context "displays line item price" do
    let(:order) { create(:order_with_totals_and_distribution, :completed) }

    specify do
      confirmation_email = Spree::OrderMailer.confirm_email_for_customer(order)
      expect(confirmation_email.body).to include("3.00")
    end

    specify do
      cancel_email = Spree::OrderMailer.cancel_email(order)
      expect(cancel_email.body).to include("3.00")
    end
  end

  describe "#cancel_email_for_shop" do
    let(:distributor) { create(:distributor_enterprise) }
    let(:order) { create(:order, distributor:, state: "canceled") }
    let(:admin_order_link_href) { "href=\"#{spree.edit_admin_order_url(order)}\"" }
    let(:mail) { Spree::OrderMailer.cancel_email_for_shop(order) }

    it "sends an email to the distributor" do
      expect(mail.to).to eq([distributor.contact.email])
    end

    it "includes a link to the cancelled order in admin" do
      expect(mail.body).to match /#{admin_order_link_href}/
    end
  end

  describe "order confimation" do
    let(:bill_address) { create(:address) }
    let(:distributor_address) {
      create(:address, address1: "distributor address", city: 'The Shire', zipcode: "1234")
    }
    let(:distributor) { create(:distributor_enterprise, address: distributor_address) }
    let(:shipping_instructions) { "pick up on thursday please!" }
    let(:ship_address) {
      create(:address, address1: "distributor address", city: 'The Shire', zipcode: "1234")
    }
    let(:order) {
      create(:order_with_line_items, distributor:, bill_address:,
                                     ship_address:,
                                     special_instructions: shipping_instructions)
    }

    describe "for customers" do
      it "should send an email to the customer when given an order" do
        Spree::OrderMailer.confirm_email_for_customer(order.id).deliver_now
        expect(ActionMailer::Base.deliveries.count).to eq(1)
        expect(ActionMailer::Base.deliveries.first.to).to eq([order.email])
      end

      it "should include SKUs" do
        mail = Spree::OrderMailer.confirm_email_for_customer(order.id)

        expect(mail.body.encoded).to include "SKU"
        expect(mail.body.encoded).to include order.line_items.first.variant.sku
      end

      it "sets a reply-to of the enterprise email" do
        Spree::OrderMailer.confirm_email_for_customer(order.id).deliver_now
        expect(ActionMailer::Base.deliveries.first.reply_to).to eq([distributor.contact.email])
      end

      it "includes a link to the configured instance email address" do
        mail = Spree::OrderMailer.confirm_email_for_customer(order.id)

        expect(mail.body.encoded).to include "mailto:hello@openfoodnetwork.org"
      end

      it "includes a link to the OFN global website if no email address is available" do
        expect(ContentConfig).to receive(:footer_email).and_return("")
        mail = Spree::OrderMailer.confirm_email_for_customer(order.id)

        expect(mail.body.encoded).to include "https://www.openfoodnetwork.org"
      end
    end

    describe "for shops" do
      it "sends an email to the shop owner when given an order" do
        Spree::OrderMailer.confirm_email_for_shop(order.id).deliver_now
        expect(ActionMailer::Base.deliveries.count).to eq(1)
        expect(ActionMailer::Base.deliveries.first.to).to eq([distributor.contact.email])
      end

      it "sends an email even if a footer_email is given" do
        # Testing bug introduced by a9c37c162e1956028704fbdf74ce1c56c5b3ce7d
        ContentConfig.footer_email = "email@example.com"
        Spree::OrderMailer.confirm_email_for_shop(order.id).deliver_now
        expect(ActionMailer::Base.deliveries.count).to eq(1)
      end
    end
  end

  describe "#invoice_email" do
    subject(:email) { described_class.invoice_email(order) }
    let(:order) { create(:completed_order_with_totals) }
    let!(:invoice_data_generator){ InvoiceDataGenerator.new(order) }
    let!(:invoice){
      create(:invoice, order:,
                       data: invoice_data_generator.serialize_for_invoice)
    }

    let(:generator){ instance_double(Orders::GenerateInvoiceService) }
    let(:renderer){ instance_double(InvoiceRenderer) }
    let(:attachment_filename){ "invoice-#{order.number}.pdf" }
    let(:deliveries){ ActionMailer::Base.deliveries }
    before do
      allow(Orders::GenerateInvoiceService).to receive(:new).with(order).and_return(generator)
      allow(InvoiceRenderer).to receive(:new).and_return(renderer)
    end
    context "When invoices feature is not enabled" do
      it "should call the invoice render with order as argument" do
        expect(generator).not_to receive(:generate_or_update_latest_invoice)
        expect(order).not_to receive(:invoices)
        expect(renderer).to receive(:render_to_string).with(order, nil).and_return("invoice")
        expect {
          email.deliver_now
        }.not_to raise_error
        expect(deliveries.count).to eq(1)
        expect(deliveries.first.attachments.count).to eq(1)
        expect(deliveries.first.attachments.first.filename).to eq(attachment_filename)
      end
    end

    context "When invoices feature is enabled", feature: :invoices do
      it "should call the invoice renderer with invoice's presenter as argument" do
        expect(generator).to receive(:generate_or_update_latest_invoice)
        expect(order).to receive(:invoices).and_return([invoice])
        expect(renderer).to receive(:render_to_string).with(invoice.presenter, nil)
        email.deliver_now
      end
    end
  end

  context "display adjustments" do
    let(:order) { create(:order_with_totals_and_distribution, :completed) }
    let(:voucher) { create(:voucher, enterprise: order.distributor) }

    before do
      voucher.create_adjustment(voucher.code, order)
      OrderManagement::Order::Updater.new(order).update_voucher
    end

    let!(:confirmation_email_for_customer) { Spree::OrderMailer.confirm_email_for_customer(order) }
    let!(:confirmation_email_for_shop) { Spree::OrderMailer.confirm_email_for_shop(order) }
    let!(:cancellation_email) { Spree::OrderMailer.cancel_email(order) }

    it "includes Voucher text with label" do
      expect(confirmation_email_for_customer.body).to include("Voucher (#{voucher.code}):")
      expect(confirmation_email_for_shop.body).to include("Voucher (#{voucher.code}):")
      expect(cancellation_email.body).to include("Voucher (#{voucher.code}):")
    end

    it "includes Shipping label" do
      expect(confirmation_email_for_customer.body).to include("Shipping:")
      expect(confirmation_email_for_shop.body).to include("Shipping:")
      expect(cancellation_email.body).to include("Shipping:")
    end
  end
end
