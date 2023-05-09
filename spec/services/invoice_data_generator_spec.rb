# frozen_string_literal: true

require 'spec_helper'

describe InvoiceDataGenerator do
  describe '#generate' do
    let!(:order) { create(:completed_order_with_fees) }
    let!(:invoice_data_generator){ InvoiceDataGenerator.new(order) }
    let!(:latest_invoice){
      create(:invoice,
             order: order,
             data: invoice_data_generator.serialize_for_invoice)
    }
    let(:new_invoice_data) {
      InvoiceDataGenerator.new(order).generate
    }
    let(:new_invoice) { create(:invoice, order: order, data: new_invoice_data) }
    let(:new_invoice_presenter) { new_invoice.presenter }

    context "mutable attribute updated" do
      it "should reflect the changes" do
        new_note = "This is an updated note"
        order.update!(note: new_note)

        expect(new_invoice_presenter.note).to eq(new_note)
      end
    end

    context "immutable attribute updated" do
      let!(:old_distributor_name) { latest_invoice.presenter.distributor.abn }
      it "should not reflect the changes" do
        order.distributor.update!(name: 'NEW ABN')
        expect(new_invoice_presenter.distributor.abn).to eq(old_distributor_name)
      end
    end

    context "shipping method" do
      it "should keep the old sm details if the shipping method id doesn't change" do
        shipping_method = order.shipping_method
        old_shipping_method_name = shipping_method.name
        shipping_method.update!(name: "NEW NAME")

        expect(new_invoice_presenter.shipping_method.name).to eq(old_shipping_method_name)
      end

      it "should update the sm details if the shipping method id is updated" do
        new_shipping_method = create(:shipping_method)
        order.distributor.shipping_methods << new_shipping_method
        order.select_shipping_method new_shipping_method.id

        expect(new_invoice_presenter.shipping_method.name).to eq(new_shipping_method.name)
      end
    end

    context "line items" do
      it "should reflect the changes" do
        line_item = order.line_items.first
        new_quantity = line_item.quantity + 1
        line_item.update!(quantity: new_quantity)

        expect(new_invoice_presenter.sorted_line_items.first.quantity).to eq(new_quantity)
      end

      it "should not reflect variant changes" do
        line_item = order.line_items.first
        old_variant_name = line_item.variant.display_name
        line_item.variant.update!(display_name: "NEW NAME")

        expect(
          new_invoice_presenter.sorted_line_items.first.variant.display_name
        ).to eq(old_variant_name)
      end
    end

    context "order without invoices" do
      let!(:order) { create(:completed_order_with_fees) }
      let(:new_invoice_data) {
        InvoiceDataGenerator.new(order).generate
      }

      it "should generate a new invoice" do
        expect(new_invoice_data).to eql InvoiceDataGenerator.new(order).serialize_for_invoice
      end
    end
  end
end
