# frozen_string_literal: true

require 'spec_helper'

describe OrderInvoiceComparator do
  describe '#can_generate_new_invoice?' do
    # this passes 'order' as argument to the invoice comparator
    let(:order) { create(:completed_order_with_fees) }
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
      it "returns false if the order didn't change" do
        expect(subject).to be false
      end

      it "returns true if a relevant attribute changes" do
        Spree::Order.where(id: order.id).update_all(payment_total: order.payment_total + 10)
        order.reload
        expect(subject).to be true
      end

      it "returns true if a relevant attribute changes" do
        Spree::Order.where(id: order.id).update_all(total: order.total + 10)
        order.reload
        expect(subject).to be true
      end

      it "returns false if an attribute which should not change, changes" do
        Spree::Order.where(id: order.id).update_all(number: 'R631504404')
        order.reload
        expect(subject).to be false
      end

      it "returns false if an attribute which should not change, changes" do
        Spree::Order.where(id: order.id).update_all(currency: 'EUR')
        order.reload
        expect(subject).to be false
      end

      it "returns true if a relevant attribute changes - order state: cancelled" do
        order.cancel!
        expect(subject).to be true
      end

      it "returns true if a relevant attribute changes - order state: resumed" do
        order.cancel!
        order.resume!
        expect(subject).to be true
      end

      it "returns false if a non-relevant attribute changes" do
        order.update!(special_instructions: "A very special insctruction.")
        expect(subject).to be false
      end

      it "returns false if a non-relevant attribute changes" do
        order.update!(note: "THIS IS A NEW NOTE")
        expect(subject).to be false
      end

      context "additional tax total changes" do
        let(:order) do
          create(:order_with_taxes, product_price: 110, tax_rate_amount: 0.1,
                                    included_in_price: false)
            .tap do |order|
            order.create_tax_charge!
            order.update_shipping_fees!
          end
        end

        it "returns returns true" do
          Spree::TaxRate.first.update!(amount: 0.15)
          order.create_tax_charge! && order.save
          expect(subject).to be true
        end
      end

      context "included tax total changes" do
        let(:order) do
          create(:order_with_taxes, product_price: 110, tax_rate_amount: 0.1,
                                    included_in_price: true)
            .tap do |order|
            order.create_tax_charge!
            order.update_shipping_fees!
          end
        end

        it "returns returns true" do
          Spree::TaxRate.first.update!(amount: 0.15)
          order.create_tax_charge! && order.save
          expect(subject).to be true
        end
      end

      context "shipping method changes" do
        let(:shipping_method) { create(:shipping_method) }
        it "returns returns true" do
          Spree::ShippingRate.first.update(shipping_method_id: shipping_method.id)
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
