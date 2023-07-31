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

      it "returns false if a non-relevant attribute changes" do
        order.update!(note: "THIS IS A NEW NOTE")
        expect(subject).to be false
      end

      context "additional tax total changes" do
        let(:distributor) { create(:distributor_enterprise) }
        let!(:order_with_taxes) do
          create(:order_with_taxes, distributor: distributor, ship_address: create(:address),
                                    product_price: 110, tax_rate_amount: 0.1, included_in_price: false,
                                    tax_rate_name: "Tax 1").tap do |order|
                                      order.create_tax_charge!
                                      order.update_shipping_fees!
                                    end
        end

        it "returns returns true" do
          expect(order_with_taxes.additional_tax_total).to eq 0.11e2
          Spree::TaxRate.first.update!(amount: 0.15)
          order_with_taxes.create_tax_charge! && order_with_taxes.save

          expect(order_with_taxes.additional_tax_total).to eq 0.165e2

          expect(subject).to be true
        end
      end

      context "included tax total changes" do
        let(:distributor) { create(:distributor_enterprise) }
        let!(:order_with_taxes) do
          create(:order_with_taxes, distributor: distributor, ship_address: create(:address),
                                    product_price: 110, tax_rate_amount: 0.1,
                                    included_in_price: true,
                                    tax_rate_name: "Tax 1").tap do |order|
                                      order.create_tax_charge!
                                      order.update_shipping_fees!
                                    end
        end

        it "returns returns true" do
          expect(order_with_taxes.included_tax_total).to eq 0.1e2
          Spree::TaxRate.first.update!(amount: 0.15)
          order_with_taxes.create_tax_charge! && order_with_taxes.save

          expect(order_with_taxes.included_tax_total).to eq 0.1435e2

          expect(subject).to be true
        end
      end

      context "shipping method changes" do
        let(:shipping_method) { create(:shipping_method) }
        let!(:order_ready_to_ship) {
          create(:order_ready_to_ship)
        }
        it "returns returns true" do
          Spree::ShippingRate.first.update(shipping_method_id: shipping_method.id)
          order_ready_to_ship.update_shipping_fees! && order_ready_to_ship.save
          expect(subject).to be true
        end
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
