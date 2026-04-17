# frozen_string_literal: true

RSpec.describe PaymentMailer do
  describe '#payment_mailer' do
    let!(:distributor) { create(:distributor_enterprise) }
    let!(:order) { create(:completed_order_with_totals, distributor: distributor) }
    let!(:payment_method) { create(:payment_method, distributors: [distributor]) }
    let!(:payment) { create(:payment, order: order, payment_method: payment_method) }

    context "authorize payment email" do
      subject(:mail) { described_class.authorize_payment(payment) }

      it "includes the distributor's name in the subject" do
        order.distributor.name = "Fennel Farmer"
        expect(mail.subject).to include("authorize your payment to Fennel Farmer")
      end

      it "sets a reply-to of the customer email" do
        expect(mail.reply_to).to eq([order.distributor.contact.email])
      end

      context "white labelling" do
        it_behaves_like 'email with inactive white labelling', :mail
        it_behaves_like 'customer facing email with active white labelling', :mail
      end

      context "enterprise logo" do
        it_behaves_like "enterprise logo rendering", :mail, :distributor
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

      context "enterprise logo" do
        it_behaves_like "enterprise logo rendering", :mail, :distributor
      end

      context "enterprise greeting" do
        let(:enterprise) { order.distributor }
        it_behaves_like 'for an enterprise with contact name present', :mail
        it_behaves_like 'for an enterprise with no contact name present', :mail
      end
    end
  end

  describe "#refund_available" do
    it "tells the user to accept a refund" do
      payment = build(:payment)
      payment.order.distributor = build(:enterprise, name: "Carrot Castle")
      link = "https://taler.example.com/order/1"
      mail = PaymentMailer.refund_available(payment.money.to_s, payment, link)

      expect(mail.subject).to eq "Refund from Carrot Castle"
      expect(mail.body).to include "Your payment of $45.75 to Carrot Castle is being refunded."
      expect(mail.body).to include link
    end
  end
end
