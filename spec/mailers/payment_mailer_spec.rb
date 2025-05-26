# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PaymentMailer do
  describe '#payment_mailer' do
    let(:enterprise) { create(:enterprise) }
    let(:payment_method) {
      create(:payment_method, distributors: [order.distributor])
    }
    let(:payment) {
      create(:payment, order:, payment_method:)
    }
    let(:order) { create(:completed_order_with_totals) }

    context "authorize payment email" do
      subject(:mail) { described_class.authorize_payment(payment) }

      it "includes the distributor's name in the subject" do
        expect(mail.subject).to include("authorize your payment to #{order.distributor.name}")
      end

      it "sets a reply-to of the customer email" do
        expect(mail.reply_to).to eq([order.distributor.contact.email])
      end

      context "white labelling" do
        it_behaves_like 'email with inactive white labelling', :mail
        it_behaves_like 'customer facing email with active white labelling', :mail
      end

      it "includes a link to authorize the payment" do
        link = "http://test.host/payments/#{payment.id}/authorize"
        expect(mail.body).to have_link link, href: link
      end
    end

    context "authorization required email" do
      subject(:mail) { described_class.authorization_required(payment) }

      it "includes the distributor's name in the subject" do
        expect(mail.subject).to include("A payment requires authorization from the customer")
      end

      it "sets a reply-to of the customer email" do
        expect(mail.reply_to).to eq([order.email])
      end

      context "white labelling" do
        it_behaves_like 'email with inactive white labelling', :mail
        it_behaves_like 'non-customer facing email with active white labelling', :mail
      end
    end
  end
end
