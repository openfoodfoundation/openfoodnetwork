# frozen_string_literal: true

require 'spec_helper'

describe OrderInvoiceComparator do
  describe '#can_generate_new_invoice?' do
    let!(:order) { create(:completed_order_with_fees) }
    let!(:invoice_data_generator){ InvoiceDataGenerator.new(order) }
    let!(:invoice){
      create(:invoice,
             order: order,
             data: invoice_data_generator.serialize_for_invoice)
    }
    let(:subject) {
      OrderInvoiceComparator.new(order).can_generate_new_invoice?
    }

    context "changes on the order object" do
      it "returns true if the order didn't change" do
        expect(subject).to be false
      end

      it "returns true if a relevant attribute changes" do
        Spree::Order.where(id: order.id).update_all(payment_total: order.payment_total + 10)
        order.reload
        expect(subject).to be true
      end

      it "returns true if a non-relevant attribute changes" do
        order.update!(note: "THIS IS A NEW NOTE")
        expect(subject).to be false
      end
    end

    context "a non-relevant associated model is updated" do
      let(:distributor){ order.distributor }
      it "returns false" do
        distributor.update!(name: 'THIS IS A NEW NAME', abn: 'This is a new ABN')
        expect(subject).to be false
      end
    end

    context "a relevant associated object is updated" do
      let(:line_item){ order.line_items.first }
      it "return true" do
        line_item.update!(quantity: line_item.quantity + 1)
        expect(subject).to be true
      end
    end
  end

  describe '#can_update_latest_invoice?' do
    let!(:order) { create(:completed_order_with_fees) }
    let!(:invoice_data_generator){ InvoiceDataGenerator.new(order) }
    let!(:invoice){
      create(:invoice,
             order: order,
             data: invoice_data_generator.serialize_for_invoice)
    }
    let(:subject) {
      OrderInvoiceComparator.new(order).can_update_latest_invoice?
    }

    context "changes on the order object" do
      it "returns true if the order didn't change" do
        expect(subject).to be false
      end

      it "returns true if a relevant attribute changes" do
        order.update!(note: "THIS IS A NEW NOTE")
        expect(subject).to be true
      end

      it "returns false if a non-relevant attribute changes" do
        Spree::Order.where(id: order.id).update_all(payment_total: order.payment_total + 10)
        order.reload
        expect(subject).to be false
      end
    end

    context "a non-relevant associated model is updated" do
      let(:distributor){ order.distributor }
      it "returns false" do
        distributor.update!(name: 'THIS IS A NEW NAME', abn: 'This is a new ABN')
        expect(subject).to be false
      end
    end

    context "a relevant associated object is updated" do
      let(:payment){ order.payments.first }
      it "return true" do
        expect(payment.state).to_not eq 'completed'
        payment.update!(state: 'completed')
        expect(subject).to be true
      end
    end
  end
end
