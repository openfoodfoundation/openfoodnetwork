# frozen_string_literal: true

require 'spec_helper'

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
      describe "detecting relevant attribute changes" do
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

        it "returns true if a relevant attribute changes - order state: cancelled" do
          order.cancel!
          expect(subject).to be true
        end

        it "returns true if a relevant attribute changes - order state: resumed" do
          order.cancel!
          order.resume!
          expect(subject).to be true
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

          it "returns true" do
            Spree::TaxRate.first.update!(amount: 0.15)
            order.create_tax_charge!
            order.reload
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

          it "returns true" do
            Spree::TaxRate.first.update!(amount: 0.15)
            order.create_tax_charge!
            order.reload
            expect(subject).to be true
          end
        end

        context "shipping method changes" do
          let(:shipping_method) { create(:shipping_method) }
          it "returns true" do
            Spree::ShippingRate.first.update(shipping_method_id: shipping_method.id)
            expect(subject).to be true
          end
        end
      end

      describe "ignoring non-relevant attribute changes" do
        it "returns false if the order didn't change" do
          expect(subject).to be false
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

        it "returns false if a non-relevant attribute changes" do
          order.update!(special_instructions: "A very special insctruction.")
          expect(subject).to be false
        end

        it "returns false if a non-relevant attribute changes" do
          order.update!(note: "THIS IS A NEW NOTE")
          expect(subject).to be false
        end
      end
    end

    context "changes on an associated order object" do
      describe "detecting relevant associated object changes" do
        context "adjustment changes" do
          it "creating a new adjustment returns true" do
            create(:adjustment, order_id: order.id)
            order.reload
            expect(subject).to be true
          end

          context "with an existing adjustment" do
            let!(:adjustment) { create(:adjustment, order_id: order.id) }

            it "editing the amount returns true" do
              adjustment.update!(amount: 123)
              order.reload
              expect(subject).to be true
            end

            it "changing the adjustment type" do
              adjustment.update!(adjustable_type: "Spree::Payment")
              order.reload
              expect(subject).to be true
            end

            it "deleting the label" do
              order.all_adjustments.destroy_all
              order.reload
              expect(subject).to be true
            end
          end
        end

        context "line item changes" do
          let(:line_item){ order.line_items.first }

          context "on quantitity" do
            it "return true" do
              line_item.update!(quantity: line_item.quantity + 1)
              expect(subject).to be true
            end
          end

          context "on variant id" do
            it "return true" do
              line_item.update!(variant_id: Spree::Variant.first.id)
              order.reload
              expect(subject).to be true
            end
          end
        end

        context "bill address changes on" do
          let(:bill_address) { Spree::Address.where(id: order.bill_address_id) }
          it "first name" do
            bill_address.update!(firstname: "Jane")
            order.reload
            expect(subject).to be true
          end

          it "last name" do
            bill_address.update!(lastname: "Jones")
            order.reload
            expect(subject).to be true
          end

          it "address (1)" do
            bill_address.update!(address1: "Rue du Fromage 66")
            order.reload
            expect(subject).to be true
          end

          it "address (2)" do
            bill_address.update!(address2: "South by Southwest")
            order.reload
            expect(subject).to be true
          end

          it "city" do
            bill_address.update!(city: "Antibes")
            order.reload
            expect(subject).to be true
          end

          it "zipcode" do
            bill_address.update!(zipcode: "04229")
            order.reload
            expect(subject).to be true
          end

          it "phone" do
            bill_address.update!(phone: "111-222-333")
            order.reload
            expect(subject).to be true
          end

          it "company" do
            bill_address.update!(company: "A Company Name")
            order.reload
            expect(subject).to be true
          end
        end

        context "ship address changes on" do
          let(:ship_address) { Spree::Address.where(id: order.ship_address_id) }
          it "first name" do
            ship_address.update!(firstname: "Jane")
            order.reload
            expect(subject).to be true
          end

          it "last name" do
            ship_address.update!(lastname: "Jones")
            order.reload
            expect(subject).to be true
          end

          it "address (1)" do
            ship_address.update!(address1: "Rue du Fromage 66")
            order.reload
            expect(subject).to be true
          end

          it "address (2)" do
            ship_address.update!(address2: "South by Southwest")
            order.reload
            expect(subject).to be true
          end

          it "city" do
            ship_address.update!(city: "Antibes")
            order.reload
            expect(subject).to be true
          end

          it "zipcode" do
            ship_address.update!(zipcode: "04229")
            order.reload
            expect(subject).to be true
          end

          it "phone" do
            ship_address.update!(phone: "111-222-333")
            order.reload
            expect(subject).to be true
          end

          it "company" do
            ship_address.update!(company: "A Company Name")
            order.reload
            expect(subject).to be true
          end
        end

        context "customer changes on" do
          let(:customer){ order.customer }

          context "code" do
            it "return false" do
              customer.update!(code: 98_754)
              order.reload
              expect(subject).to be false
            end
          end

          context "email" do
            it "return false" do
              customer.update!(email: "customer@email.org")
              order.reload
              expect(subject).to be false
            end
          end
        end

        context "payment changes on" do
          let(:payment) { create(:payment, order_id: order.id) }
          context "amount" do
            it "returns true" do
              payment.update!(amount: 222)
              order.reload
              expect(subject).to be true
            end
          end

          context "payment method" do
            let(:payment_method) { create(:payment_method) }

            it "returns true" do
              payment.update!(payment_method_id: payment_method.id)
              order.reload
              expect(subject).to be true
            end
          end
        end
      end

      describe "ignoring non-relevant associated object changes" do
        context "customer changes" do
          let(:customer){ create(:customer) }
          it "returns false" do
            order.update!(customer_id: customer.id)
            expect(subject).to be false
          end
        end

        context "distributor changes" do
          let(:distributor){ order.distributor }
          it "returns false" do
            distributor.update!(name: 'THIS IS A NEW NAME', abn: 'This is a new ABN')
            expect(subject).to be false
          end
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
      it "returns false if the order didn't change" do
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

      context "payment changes on" do
        context "state" do
          let(:payment) { order.payments.first }
          it "returns true" do
            expect {
              payment.started_processing
            }.to change { payment.state }.from("checkout").to("processing")

            order.reload
            expect(subject).to be true
          end
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
      describe "detecting relevant associated object changes" do
        context "adjustment changes" do
          context "with an existing adjustment" do
            let!(:adjustment) { create(:adjustment, order_id: order.id) }
            it "changing the label returns true" do
              adjustment.update!(label: "It's a new label")
              order.reload
              expect(subject).to be true
            end
          end
        end
        context "payment changes" do
          let(:payment){ order.payments.first }
          it "return true" do
            expect(payment.state).to_not eq 'completed'
            payment.update!(state: 'completed')
            expect(subject).to be true
          end
        end
      end
    end
  end
end
