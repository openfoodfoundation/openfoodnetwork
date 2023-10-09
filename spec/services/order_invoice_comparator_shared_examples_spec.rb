# frozen_string_literal: true

require 'spec_helper'

shared_examples "attribute changes - payment total" do |boolean, type|
  before do
    Spree::Order.where(id: order.id).update_all(payment_total: order.payment_total + 10)
  end

  it "returns #{boolean} if a #{type} attribute changes" do
    order.reload
    expect(subject).to be boolean
  end
end

shared_examples "attribute changes - order total" do |boolean, type|
  before do
    Spree::Order.where(id: order.id).update_all(total: order.total + 10)
  end

  it "returns #{boolean} if a #{type} attribute changes" do
    order.reload
    expect(subject).to be boolean
  end
end

shared_examples "attribute changes - order state: cancelled" do |boolean, type|
  before do
    order.cancel!
  end

  it "returns #{boolean} if a #{type} attribute changes" do
    order.reload
    expect(subject).to be boolean
  end
end

describe OrderInvoiceComparator do
  describe '#can_generate_new_invoice?' do
    # this passes 'order' as argument to the invoice comparator
    let(:order) { create(:completed_order_with_fees) }
    let!(:invoice_data_generator){ InvoiceDataGenerator.new(order) }
    let!(:invoice){
      create(:invoice,
             order:,
             data: invoice_data_generator.serialize_for_invoice)
    }
    let(:subject) {
      OrderInvoiceComparator.new(order).can_generate_new_invoice?
    }

    context "changes on the order object" do
      describe "detecting relevant" do
        it_behaves_like "attribute changes - payment total", true, "relevant"
        it_behaves_like "attribute changes - order total", true, "relevant"
      end

      describe "detecting non-relevant" do
        pending('A new invoice should not be generated upon order state change') do
          it_behaves_like "attribute changes - order state: cancelled", false, "non-relevant"
        end
      end
    end
  end

  describe '#can_update_latest_invoice?' do
    let!(:order) { create(:completed_order_with_fees) }
    let!(:invoice_data_generator){ InvoiceDataGenerator.new(order) }
    let!(:invoice){
      create(:invoice,
             order:,
             data: invoice_data_generator.serialize_for_invoice)
    }
    let(:subject) {
      OrderInvoiceComparator.new(order).can_update_latest_invoice?
    }

    context "changes on the order object" do
      describe "detecting relevant" do
        it_behaves_like "attribute changes - order state: cancelled", true, "relevant"
      end

      describe "detecting non-relevant" do
        it_behaves_like "attribute changes - payment total", false, "non-relevant"
        it_behaves_like "attribute changes - order total", false, "non-relevant"
      end
    end
  end
end
