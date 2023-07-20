# frozen_string_literal: true

require "spec_helper"

describe OrderSyncer do
  describe "updating the shipping method" do
    let!(:subscription) { create(:subscription, with_items: true, with_proxy_orders: true) }
    let!(:order) { subscription.proxy_orders.first.initialise_order! }
    let!(:shipping_method) { subscription.shipping_method }
    let!(:new_shipping_method) { create(:shipping_method, distributors: [subscription.shop]) }

    let(:syncer) { OrderSyncer.new(subscription) }

    context "when the shipping method on an order is the same as the subscription" do
      let(:params) { { shipping_method_id: new_shipping_method.id } }

      before do
        # Create shipping rates for available shipping methods.
        order.shipments.each(&:refresh_rates)
        order.select_shipping_method(shipping_method)
      end

      it "updates the shipping_method on the order and on shipments" do
        expect(order.shipments.first.shipping_method).to eq shipping_method
        subscription.assign_attributes(params)
        expect(syncer.sync!).to be true
        expect(order.reload.shipping_method).to eq new_shipping_method
        expect(order.shipments.first.shipping_method).to eq new_shipping_method
      end
    end

    context "when the shipping method on a shipment is not the same " \
            "as the original shipping method on the subscription" do
      let(:params) { { shipping_method_id: new_shipping_method.id } }

      context "when the shipping method on a shipment is the same as the new shipping method " \
              "on the subscription" do
        before do
          # Create shipping rates for available shipping methods.
          order.shipments.each(&:refresh_rates)

          # Updating the shipping method on a shipment updates the shipping method on the order,
          # and vice-versa via logic in Spree's shipments controller. So updating both here mimics
          # that behaviour.
          order.select_shipping_method(new_shipping_method.id)
          subscription.assign_attributes(params)
          expect(syncer.sync!).to be true
        end

        it "does not update the shipping_method on the subscription or " \
           "on the pre-altered shipment" do
          expect(order.reload.shipping_method).to eq new_shipping_method
          expect(order.reload.shipments.first.shipping_method).to eq new_shipping_method
          expect(syncer.order_update_issues[order.id]).to be nil
        end
      end

      context "when the shipping method on a shipment is not the same as the new shipping method " \
              "on the subscription" do
        let!(:changed_shipping_method) { create(:shipping_method) }

        before do
          # Create shipping rates for available shipping methods.
          order.shipments.each(&:refresh_rates)

          # Updating the shipping method on a shipment updates the shipping method on the order,
          # and vice-versa via logic in Spree's shipments controller. So updating both here mimics
          # that behaviour.
          order.select_shipping_method(changed_shipping_method.id)
          subscription.assign_attributes(params)

          expect(syncer.sync!).to be true
        end

        it "does not update the shipping_method on the subscription or " \
           "on the pre-altered shipment" do
          expect(order.reload.shipping_method).to eq changed_shipping_method
          expect(order.reload.shipments.first.shipping_method).to eq changed_shipping_method
          expect(syncer.order_update_issues[order.id]).to include "Shipping Method"
        end
      end
    end
  end

  describe "changing the payment method" do
    let(:subscription) { create(:subscription, with_items: true, with_proxy_orders: true) }
    let(:order) { subscription.proxy_orders.first.initialise_order! }
    let(:payment_method) { subscription.payment_method }
    let(:new_payment_method) { create(:payment_method, distributors: [subscription.shop]) }
    let(:invalid_payment_method) { create(:payment_method, distributors: [create(:enterprise)]) }
    let(:bogus_payment_method) { create(:bogus_payment_method, distributors: [subscription.shop]) }
    let(:syncer) { OrderSyncer.new(subscription) }

    context "when the payment method on an order is the same as the subscription" do
      let(:params) { { payment_method_id: new_payment_method.id } }

      it "voids existing payments and creates a new payment with the relevant payment method" do
        expect(order.payments.reload.first.payment_method).to eq payment_method
        subscription.assign_attributes(params)
        expect(syncer.sync!).to be true
        payments = order.reload.payments
        expect(payments.count).to be 2
        expect(payments.with_state('void').count).to be 1
        expect(payments.with_state('checkout').count).to be 1
        expect(payments.with_state('void').first.payment_method).to eq payment_method
        expect(payments.with_state('checkout').first.payment_method).to eq new_payment_method
      end
    end

    context "when the payment method on a payment is not the same as the subscription" do
      let(:params) { { payment_method_id: new_payment_method.id } }

      context "when the payment method on a payment is the same as the original payment method " \
              "on the subscription" do
        before do
          order.payments.first.update_attribute(:payment_method_id, new_payment_method.id)
          subscription.assign_attributes(params)
          expect(syncer.sync!).to be true
        end

        it "keeps pre-altered payments and doesn't add an issue to order_update_issues" do
          payments = order.reload.payments
          expect(payments.count).to be 1
          expect(payments.first.payment_method).to eq new_payment_method
          expect(syncer.order_update_issues[order.id]).to be nil
        end
      end

      context "when the payment method on a shipment is not the same " \
              "as the original payment method on the subscription" do
        let(:changed_payment_method) { create(:payment_method) }

        before do
          order.payments.first.update_attribute(:payment_method_id, changed_payment_method.id)
          subscription.assign_attributes(params)
          expect(syncer.sync!).to be true
        end

        it "keeps pre-altered payments and adds an issue to order_update_issues" do
          payments = order.reload.payments
          expect(payments.count).to be 1
          expect(payments.first.payment_method).to eq changed_payment_method
          expect(syncer.order_update_issues[order.id]).to include "Payment Method"
        end
      end
    end
  end

  describe "changing the billing address" do
    let!(:distributor_address) { create(:address, :randomized) }
    let!(:distributor) { create(:distributor_enterprise, address: distributor_address) }
    let(:subscription) do
      create(:subscription, shop: distributor, shipping_method: shipping_method, with_items: true,
                            with_proxy_orders: true)
    end
    let!(:order) { subscription.proxy_orders.first.initialise_order! }
    let!(:bill_address_attrs) { subscription.bill_address.attributes }
    let!(:ship_address_attrs) { subscription.ship_address.attributes }

    let(:params) {
      { bill_address_attributes: { id: bill_address_attrs["id"], firstname: "Bill",
                                   address1: "123 abc st", phone: "1123581321" } }
    }
    let(:syncer) { OrderSyncer.new(subscription) }

    context "when a ship address is not required" do
      let!(:shipping_method) do
        create(:shipping_method, distributors: [distributor], require_ship_address: false)
      end

      context "when the bill_address on the order matches that on the subscription" do
        it "updates all bill_address attrs and ship_address names + phone" do
          subscription.assign_attributes(params)
          expect(syncer.sync!).to be true
          expect(syncer.order_update_issues.keys).to_not include order.id
          order.reload;
          expect(order.bill_address.firstname).to eq "Bill"
          expect(order.bill_address.lastname).to eq bill_address_attrs["lastname"]
          expect(order.bill_address.address1).to eq "123 abc st"
          expect(order.bill_address.phone).to eq "1123581321"
          expect(order.ship_address.firstname).to eq "Bill"
          expect(order.ship_address.lastname).to eq bill_address_attrs["lastname"]
          expect(order.ship_address.address1).to eq distributor_address.address1
          expect(order.ship_address.phone).to eq "1123581321"
        end
      end

      context "when the bill_address on the order doesn't match that on the subscription" do
        before do
          order.bill_address.update!(firstname: "Jane")
          order.update_order!
        end

        it "does not update bill_address or ship_address on the order" do
          subscription.assign_attributes(params)
          expect(syncer.sync!).to be true
          expect(syncer.order_update_issues.keys).to include order.id
          order.reload;
          expect(order.bill_address.firstname).to eq "Jane"
          expect(order.bill_address.lastname).to eq bill_address_attrs["lastname"]
          expect(order.bill_address.address1).to eq bill_address_attrs["address1"]
          expect(order.bill_address.phone).to eq bill_address_attrs["phone"]
          expect(order.ship_address.firstname).to eq "Jane"
          expect(order.ship_address.lastname).to eq bill_address_attrs["lastname"]
          expect(order.ship_address.address1).to eq distributor_address.address1
          expect(order.ship_address.phone).to eq bill_address_attrs["phone"]
        end
      end
    end

    context "when a ship address is required" do
      let!(:shipping_method) do
        create(:shipping_method, distributors: [distributor], require_ship_address: true)
      end

      context "when the bill_address on the order matches that on the subscription" do
        it "only updates bill_address attrs" do
          subscription.assign_attributes(params)
          expect(syncer.sync!).to be true
          expect(syncer.order_update_issues.keys).to_not include order.id
          order.reload;
          expect(order.bill_address.firstname).to eq "Bill"
          expect(order.bill_address.lastname).to eq bill_address_attrs["lastname"]
          expect(order.bill_address.address1).to eq "123 abc st"
          expect(order.bill_address.phone).to eq "1123581321"
          expect(order.ship_address.firstname).to eq ship_address_attrs["firstname"]
          expect(order.ship_address.lastname).to eq ship_address_attrs["lastname"]
          expect(order.ship_address.address1).to eq ship_address_attrs["address1"]
          expect(order.ship_address.phone).to eq ship_address_attrs["phone"]
        end
      end

      context "when the bill_address on the order doesn't match that on the subscription" do
        before do
          order.bill_address.update!(firstname: "Jane")
          order.update_order!
        end

        it "does not update bill_address or ship_address on the order" do
          subscription.assign_attributes(params)
          expect(syncer.sync!).to be true
          expect(syncer.order_update_issues.keys).to include order.id
          order.reload;
          expect(order.bill_address.firstname).to eq "Jane"
          expect(order.bill_address.lastname).to eq bill_address_attrs["lastname"]
          expect(order.bill_address.address1).to eq bill_address_attrs["address1"]
          expect(order.bill_address.phone).to eq bill_address_attrs["phone"]
          expect(order.ship_address.firstname).to eq ship_address_attrs["firstname"]
          expect(order.ship_address.lastname).to eq ship_address_attrs["lastname"]
          expect(order.ship_address.address1).to eq ship_address_attrs["address1"]
          expect(order.ship_address.phone).to eq ship_address_attrs["phone"]
        end
      end
    end
  end

  describe "changing the ship address" do
    let!(:distributor_address) { create(:address, :randomized) }
    let!(:distributor) { create(:distributor_enterprise, address: distributor_address) }
    let!(:subscription) do
      create(:subscription, shop: distributor, shipping_method: shipping_method, with_items: true,
                            with_proxy_orders: true)
    end
    let!(:order) { subscription.proxy_orders.first.initialise_order! }
    let!(:bill_address_attrs) { subscription.bill_address.attributes }
    let!(:ship_address_attrs) { subscription.ship_address.attributes }

    let(:params) {
      { ship_address_attributes: { id: ship_address_attrs["id"], firstname: "Ship",
                                   address1: "123 abc st", phone: "1123581321" } }
    }
    let(:syncer) { OrderSyncer.new(subscription) }

    context "when a ship address is not required" do
      let!(:shipping_method) do
        create(:shipping_method, distributors: [distributor], require_ship_address: false)
      end

      it "does not change the ship address" do
        subscription.assign_attributes(params)
        expect(syncer.sync!).to be true
        expect(syncer.order_update_issues.keys).to_not include order.id
        order.reload;
        expect(order.ship_address.firstname).to eq bill_address_attrs["firstname"]
        expect(order.ship_address.lastname).to eq bill_address_attrs["lastname"]
        expect(order.ship_address.address1).to eq distributor_address.address1
        expect(order.ship_address.phone).to eq bill_address_attrs["phone"]
      end

      context "but the shipping method is being changed to one that requires a ship_address" do
        let(:new_shipping_method) {
          create(:shipping_method, distributors: [distributor], require_ship_address: true)
        }

        before { params.merge!(shipping_method_id: new_shipping_method.id) }

        context "when the original ship address is the bill contact using distributor address" do
          let!(:original_bill_address) { create(:address, :randomized) }
          let!(:original_ship_address) do
            create(:address, firstname: original_bill_address.firstname,
                             lastname: original_bill_address.lastname,
                             address1: distributor_address.address1,
                             phone: original_bill_address.phone,
                             city: distributor_address.city,
                             zipcode: distributor_address.zipcode)
          end
          let(:subscription) do
            create(:subscription, shop: distributor, bill_address: original_bill_address,
                                  ship_address: original_ship_address,
                                  shipping_method: shipping_method, with_items: true,
                                  with_proxy_orders: true)
          end

          context "when there is no pending shipment using the former shipping method" do
            before do
              order.shipment.destroy
              subscription.assign_attributes(params)
            end

            it "updates ship_address attrs" do
              expect(syncer.sync!).to be true
              expect(syncer.order_update_issues.keys).to include order.id
              order.reload
              expect(order.ship_address.firstname).to eq ship_address_attrs["firstname"]
              expect(order.ship_address.lastname).to eq ship_address_attrs["lastname"]
              expect(order.ship_address.address1).to eq ship_address_attrs["address1"]
              expect(order.ship_address.phone).to eq ship_address_attrs["phone"]
            end
          end

          context "when the order has a pending shipment using the former shipping method" do
            before do
              subscription.assign_attributes(params)
            end

            it "updates ship_address attrs" do
              expect(syncer.sync!).to be true
              expect(syncer.order_update_issues.keys).not_to include order.id
              order.reload
              expect(order.ship_address.firstname).to eq "Ship"
              expect(order.ship_address.lastname).to eq ship_address_attrs["lastname"]
              expect(order.ship_address.address1).to eq "123 abc st"
              expect(order.ship_address.phone).to eq "1123581321"
            end
          end
        end
      end
    end

    context "when a ship address is required" do
      let!(:shipping_method) do
        create(:shipping_method, distributors: [distributor], require_ship_address: true)
      end

      context "when the ship address on the order matches that on the subscription" do
        it "updates ship_address attrs" do
          subscription.assign_attributes(params)
          expect(syncer.sync!).to be true
          expect(syncer.order_update_issues.keys).to_not include order.id
          order.reload;
          expect(order.ship_address.firstname).to eq "Ship"
          expect(order.ship_address.lastname).to eq ship_address_attrs["lastname"]
          expect(order.ship_address.address1).to eq "123 abc st"
          expect(order.ship_address.phone).to eq "1123581321"
        end
      end

      context "when the ship address on the order doesn't match that on the subscription" do
        before do
          order.ship_address.update(firstname: "Jane")
          order.update_order!
        end

        it "does not update ship_address on the order" do
          subscription.assign_attributes(params)
          expect(syncer.sync!).to be true
          expect(syncer.order_update_issues.keys).to include order.id
          order.reload;
          expect(order.ship_address.firstname).to eq "Jane"
          expect(order.ship_address.lastname).to eq ship_address_attrs["lastname"]
          expect(order.ship_address.address1).to eq ship_address_attrs["address1"]
          expect(order.ship_address.phone).to eq ship_address_attrs["phone"]
        end
      end
    end
  end

  describe "changing the quantity of a line item" do
    let(:subscription) { create(:subscription, with_items: true, with_proxy_orders: true) }
    let(:order) { subscription.proxy_orders.first.initialise_order! }
    let(:sli) { subscription.subscription_line_items.first }
    let(:variant) { sli.variant }

    before { variant.update_attribute(:on_hand, 2) }

    context "when quantity is within available stock" do
      let(:params) { { subscription_line_items_attributes: [{ id: sli.id, quantity: 2 }] } }
      let(:syncer) { OrderSyncer.new(subscription) }

      it "updates the line_item quantities and totals on all orders" do
        expect(order.reload.total.to_f).to eq 59.97
        subscription.assign_attributes(params)
        expect(syncer.sync!).to be true
        line_items = Spree::LineItem.where(order_id: subscription.orders,
                                           variant_id: sli.variant_id)
        expect(line_items.map(&:quantity)).to eq [2]
        expect(order.reload.total.to_f).to eq 79.96
      end
    end

    context "when quantity is greater than available stock" do
      let(:params) { { subscription_line_items_attributes: [{ id: sli.id, quantity: 3 }] } }
      let(:syncer) { OrderSyncer.new(subscription) }

      before do
        expect(order.reload.total.to_f).to eq 59.97
        subscription.assign_attributes(params)
      end

      context "when order is not complete" do
        it "updates the line_item quantities and totals on all orders" do
          expect(syncer.sync!).to be true

          line_items = Spree::LineItem.where(order_id: subscription.orders,
                                             variant_id: sli.variant_id)
          expect(line_items.map(&:quantity)).to eq [3]
          expect(order.reload.total.to_f).to eq 99.95
        end
      end

      context "when order is complete" do
        it "does not update the line_item quantities and adds the order " \
           "to order_update_issues with insufficient stock" do
          OrderWorkflow.new(order).complete

          expect(syncer.sync!).to be true

          line_items = Spree::LineItem.where(order_id: subscription.orders,
                                             variant_id: sli.variant_id)
          expect(line_items.map(&:quantity)).to eq [1]
          expect(order.reload.total.to_f).to eq 59.97
          line_item = order.line_items.find_by(variant_id: sli.variant_id)
          expect(syncer.order_update_issues[order.id])
            .to include "#{line_item.product.name} - #{line_item.variant.full_name} - " \
                        "Insufficient stock available"
        end

        it "does not update the line_item quantities and adds the order " \
           "to order_update_issues with out of stock" do
          # this single item available is used when the order is completed below,
          # making the item out of stock
          variant.update_attribute(:on_hand, 1)
          OrderWorkflow.new(order).complete

          expect(syncer.sync!).to be true

          line_item = order.line_items.find_by(variant_id: sli.variant_id)
          expect(syncer.order_update_issues[order.id])
            .to include "#{line_item.product.name} - #{line_item.variant.full_name} - Out of Stock"
        end
      end
    end

    context "where the quantity of the item on an initialised order has already been changed" do
      let(:params) { { subscription_line_items_attributes: [{ id: sli.id, quantity: 3 }] } }
      let(:syncer) { OrderSyncer.new(subscription) }
      let(:changed_line_item) { order.line_items.find_by(variant_id: sli.variant_id) }

      before { variant.update_attribute(:on_hand, 3) }

      context "when the changed line_item quantity matches the new quantity " \
              "on the subscription line item" do
        before do
          changed_line_item.update(quantity: 3)
          order.update_order!
        end

        it "does not change the quantity, and doesn't add the order to order_update_issues" do
          expect(order.reload.total.to_f).to eq 99.95
          subscription.assign_attributes(params)
          expect(syncer.sync!).to be true
          expect(changed_line_item.reload.quantity).to eq 3
          expect(order.reload.total.to_f).to eq 99.95
          expect(syncer.order_update_issues[order.id]).to be nil
        end
      end

      context "when the changed line_item quantity doesn't match the new quantity " \
              "on the subscription line item" do
        before do
          changed_line_item.update(quantity: 2)
          order.update_order!
        end

        it "does not change the quantity, and adds the order to order_update_issues" do
          expect(order.reload.total.to_f).to eq 79.96

          subscription.assign_attributes(params)
          expect(syncer.sync!).to be true

          expect(changed_line_item.reload.quantity).to eq 2
          expect(order.reload.total.to_f).to eq 79.96
          expect(syncer.order_update_issues[order.id])
            .to include "#{changed_line_item.product.name} - #{changed_line_item.variant.full_name}"
        end
      end
    end
  end

  describe "adding a new line item" do
    let(:subscription) { create(:subscription, with_items: true, with_proxy_orders: true) }
    let(:order) { subscription.proxy_orders.first.initialise_order! }
    let(:variant) { create(:variant) }
    let(:syncer) { OrderSyncer.new(subscription) }

    before do
      expect(order.reload.total.to_f).to eq 59.97
      subscription.assign_attributes(params)
    end

    context "when quantity is within available stock" do
      let(:params) {
        { subscription_line_items_attributes: [{ id: nil, variant_id: variant.id, quantity: 1 }] }
      }

      it "adds the line item and updates the total on all orders" do
        expect(syncer.sync!).to be true

        line_items = Spree::LineItem.where(order_id: subscription.orders, variant_id: variant.id)
        expect(line_items.map(&:quantity)).to eq [1]
        expect(order.reload.total.to_f).to eq 79.96
      end
    end

    context "when quantity is greater than available stock" do
      let(:params) {
        { subscription_line_items_attributes: [{ id: nil, variant_id: variant.id, quantity: 7 }] }
      }

      context "when order is not complete" do
        it "adds the line_item and updates totals on all orders" do
          expect(syncer.sync!).to be true

          line_items = Spree::LineItem.where(order_id: subscription.orders, variant_id: variant.id)
          expect(line_items.map(&:quantity)).to eq [7]
          expect(order.reload.total.to_f).to eq 199.9
        end
      end

      context "when order is complete" do
        before { OrderWorkflow.new(order).complete }

        it "does not add line_item and adds the order to order_update_issues" do
          expect(syncer.sync!).to be true

          line_items = Spree::LineItem.where(order_id: subscription.orders, variant_id: variant.id)
          expect(line_items.map(&:quantity)).to eq []
          expect(order.reload.total.to_f).to eq 59.97
          expect(syncer.order_update_issues[order.id])
            .to include "#{variant.product.name} - #{variant.full_name} " \
                        "- Insufficient stock available"
        end

        context "and then updating the quantity of that subscription line item " \
                "that was not added to the completed order" do
          it "does nothing to the order and adds the order to order_update_issues" do
            expect(syncer.sync!).to be true

            line_items = Spree::LineItem.where(order_id: subscription.orders,
                                               variant_id: variant.id)
            expect(line_items.map(&:quantity)).to eq []

            subscription.save # this is necessary to get an id on the subscription_line_items
            params = { subscription_line_items_attributes: [{
              id: subscription.subscription_line_items.last.id, quantity: 2
            }] }
            subscription.assign_attributes(params)
            expect(syncer.sync!).to be true

            line_items = Spree::LineItem.where(order_id: subscription.orders,
                                               variant_id: variant.id)
            expect(line_items.map(&:quantity)).to eq []
            expect(syncer.order_update_issues[order.id])
              .to include "#{variant.product.name} - #{variant.full_name}"
          end
        end
      end
    end
  end

  describe "removing an existing line item" do
    let(:subscription) { create(:subscription, with_items: true, with_proxy_orders: true) }
    let(:order) { subscription.proxy_orders.first.initialise_order! }
    let(:sli) { subscription.subscription_line_items.first }
    let(:variant) { sli.variant }
    let(:params) { { subscription_line_items_attributes: [{ id: sli.id, _destroy: true }] } }
    let(:syncer) { OrderSyncer.new(subscription) }

    it "removes the line item and updates totals on all orders" do
      expect(order.reload.total.to_f).to eq 59.97
      subscription.assign_attributes(params)
      expect(syncer.sync!).to be true
      line_items = Spree::LineItem.where(order_id: subscription.orders, variant_id: variant.id)
      expect(line_items.count).to be 0
      expect(order.reload.total.to_f).to eq 39.98
    end
  end
end
