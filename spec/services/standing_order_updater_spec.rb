describe StandingOrderUpdater do
  describe "updating the shipping method" do
    let(:standing_order) { create(:standing_order, with_items: true, with_proxy_orders: true) }
    let(:order) { standing_order.proxy_orders.first.initialise_order! }
    let(:shipping_method) { standing_order.shipping_method }
    let(:new_shipping_method) { create(:shipping_method, distributors: [standing_order.shop]) }
    let(:updater) { StandingOrderUpdater.new(standing_order) }

    context "when the shipping method on an order is the same as the standing order" do
      let(:params) { { shipping_method_id: new_shipping_method.id } }

      it "updates the shipping_method on the order and on shipments" do
        expect(order.shipments.first.shipping_method_id_was).to eq shipping_method.id
        standing_order.assign_attributes(params)
        expect(updater.update!).to be true
        expect(order.reload.shipping_method).to eq new_shipping_method
        expect(order.shipments.first.shipping_method).to eq new_shipping_method
      end
    end

    context "when the shipping method on a shipment is not the same as the original shipping method on the standing order" do
      let(:params) { { shipping_method_id: new_shipping_method.id } }

      context "when the shipping method on a shipment is the same as the new shipping method on the standing order" do
        before do
          # Updating the shipping method on a shipment updates the shipping method on the order,
          # and vice-versa via logic in Spree's shipments controller. So updating both here mimics that
          # behaviour.
          order.shipments.first.update_attributes(shipping_method_id: new_shipping_method.id)
          order.update_attributes(shipping_method_id: new_shipping_method.id)
          standing_order.assign_attributes(params)
          expect(updater.update!).to be true
        end

        it "does not update the shipping_method on the standing order or on the pre-altered shipment" do
          expect(order.reload.shipping_method).to eq new_shipping_method
          expect(order.reload.shipments.first.shipping_method).to eq new_shipping_method
          expect(updater.order_update_issues[order.id]).to be nil
        end
      end

      context "when the shipping method on a shipment is not the same as the new shipping method on the standing order" do
        let(:changed_shipping_method) { create(:shipping_method) }

        before do
          # Updating the shipping method on a shipment updates the shipping method on the order,
          # and vice-versa via logic in Spree's shipments controller. So updating both here mimics that
          # behaviour.
          order.shipments.first.update_attributes(shipping_method_id: changed_shipping_method.id)
          order.update_attributes(shipping_method_id: changed_shipping_method.id)
          standing_order.assign_attributes(params)
          expect(updater.update!).to be true
        end

        it "does not update the shipping_method on the standing order or on the pre-altered shipment" do
          expect(order.reload.shipping_method).to eq changed_shipping_method
          expect(order.reload.shipments.first.shipping_method).to eq changed_shipping_method
          expect(updater.order_update_issues[order.id]).to include "Shipping Method"
        end
      end
    end
  end

  describe "changing the payment method" do
    let(:standing_order) { create(:standing_order, with_items: true, with_proxy_orders: true) }
    let(:order) { standing_order.proxy_orders.first.initialise_order! }
    let(:payment_method) { standing_order.payment_method }
    let(:new_payment_method) { create(:payment_method, distributors: [standing_order.shop]) }
    let(:invalid_payment_method) { create(:payment_method, distributors: [create(:enterprise)]) }
    let(:bogus_payment_method) { create(:bogus_payment_method, distributors: [standing_order.shop]) }
    let(:updater) { StandingOrderUpdater.new(standing_order) }

    context "when the payment method on an order is the same as the standing order" do
      let(:params) { { payment_method_id: new_payment_method.id } }

      it "voids existing payments and creates a new payment with the relevant payment method" do
        expect(order.payments.reload.first.payment_method).to eq payment_method
        standing_order.assign_attributes(params)
        expect(updater.update!).to be true
        payments = order.reload.payments
        expect(payments.count).to be 2
        expect(payments.with_state('void').count).to be 1
        expect(payments.with_state('checkout').count).to be 1
        expect(payments.with_state('void').first.payment_method).to eq payment_method
        expect(payments.with_state('checkout').first.payment_method).to eq new_payment_method
      end
    end

    context "when the payment method on a payment is not the same as the standing order" do
      let(:params) { { payment_method_id: new_payment_method.id } }

      context "when the payment method on a payment is the same as the original payment method on the standing order" do
        before do
          order.payments.first.update_attribute(:payment_method_id, new_payment_method.id)
          standing_order.assign_attributes(params)
          expect(updater.update!).to be true
        end

        it "keeps pre-altered payments and doesn't add an issue to order_update_issues" do
          payments = order.reload.payments
          expect(payments.count).to be 1
          expect(payments.first.payment_method).to eq new_payment_method
          expect(updater.order_update_issues[order.id]).to be nil
        end
      end

      context "when the payment method on a shipment is not the same as the original payment method on the standing order" do
        let(:changed_payment_method) { create(:payment_method) }

        before do
          order.payments.first.update_attribute(:payment_method_id, changed_payment_method.id)
          standing_order.assign_attributes(params)
          expect(updater.update!).to be true
        end

        it "keeps pre-altered payments and adds an issue to order_update_issues" do
          payments = order.reload.payments
          expect(payments.count).to be 1
          expect(payments.first.payment_method).to eq changed_payment_method
          expect(updater.order_update_issues[order.id]).to include "Payment Method"
        end
      end
    end
  end

  describe "changing the billing address" do
    let(:standing_order) { create(:standing_order, with_items: true, with_proxy_orders: true) }
    let(:shipping_method) { standing_order.shipping_method }
    let!(:order) { standing_order.proxy_orders.first.initialise_order! }
    let!(:bill_address_attrs) { standing_order.bill_address.attributes }
    let!(:ship_address_attrs) { standing_order.ship_address.attributes }
    let(:params) { { bill_address_attributes: { id: bill_address_attrs["id"], firstname: "Bill", address1: "123 abc st", phone: "1123581321" } } }
    let(:updater) { StandingOrderUpdater.new(standing_order) }

    context "when a ship address is not required" do
      before { shipping_method.update_attributes(require_ship_address: false) }

      context "when the bill_address on the order matches that on the standing order" do
        it "updates all bill_address attrs and ship_address names + phone" do
          standing_order.assign_attributes(params)
          expect(updater.update!).to be true
          expect(updater.order_update_issues.keys).to_not include order.id
          order.reload;
          expect(order.bill_address.firstname).to eq "Bill"
          expect(order.bill_address.lastname).to eq bill_address_attrs["lastname"]
          expect(order.bill_address.address1).to eq "123 abc st"
          expect(order.bill_address.phone).to eq "1123581321"
          expect(order.ship_address.firstname).to eq "Bill"
          expect(order.ship_address.lastname).to eq ship_address_attrs["lastname"]
          expect(order.ship_address.address1).to eq ship_address_attrs["address1"]
          expect(order.ship_address.phone).to eq "1123581321"
        end
      end

      context "when the bill_address on the order doesn't match that on the standing order" do
        before { order.bill_address.update_attributes(firstname: "Jane") }
        it "does not update bill_address or ship_address on the order" do
          standing_order.assign_attributes(params)
          expect(updater.update!).to be true
          expect(updater.order_update_issues.keys).to include order.id
          order.reload;
          expect(order.bill_address.firstname).to eq "Jane"
          expect(order.bill_address.lastname).to eq bill_address_attrs["lastname"]
          expect(order.bill_address.address1).to eq bill_address_attrs["address1"]
          expect(order.bill_address.phone).to eq bill_address_attrs["phone"]
          expect(order.ship_address.firstname).to eq "Jane"
          expect(order.ship_address.lastname).to eq ship_address_attrs["lastname"]
          expect(order.ship_address.address1).to eq ship_address_attrs["address1"]
          expect(order.ship_address.phone).to eq ship_address_attrs["phone"]
        end
      end
    end

    context "when a ship address is required" do
      before { shipping_method.update_attributes(require_ship_address: true) }

      context "when the bill_address on the order matches that on the standing order" do
        it "only updates bill_address attrs" do
          standing_order.assign_attributes(params)
          expect(updater.update!).to be true
          expect(updater.order_update_issues.keys).to_not include order.id
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

      context "when the bill_address on the order doesn't match that on the standing order" do
        before { order.bill_address.update_attributes(firstname: "Jane") }

        it "does not update bill_address or ship_address on the order" do
          standing_order.assign_attributes(params)
          expect(updater.update!).to be true
          expect(updater.order_update_issues.keys).to include order.id
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
    let(:standing_order) { create(:standing_order, with_items: true, with_proxy_orders: true) }
    let(:shipping_method) { standing_order.shipping_method }
    let!(:order) { standing_order.proxy_orders.first.initialise_order! }
    let!(:bill_address_attrs) { standing_order.bill_address.attributes }
    let!(:ship_address_attrs) { standing_order.ship_address.attributes }
    let(:params) { { ship_address_attributes: { id: ship_address_attrs["id"], firstname: "Ship", address1: "123 abc st", phone: "1123581321" } } }
    let(:updater) { StandingOrderUpdater.new(standing_order) }

    context "when a ship address is not required" do
      before { shipping_method.update_attributes(require_ship_address: false) }

      it "does not change the ship address" do
        standing_order.assign_attributes(params)
        expect(updater.update!).to be true
        expect(updater.order_update_issues.keys).to_not include order.id
        order.reload;
        expect(order.ship_address.firstname).to eq ship_address_attrs["firstname"]
        expect(order.ship_address.lastname).to eq ship_address_attrs["lastname"]
        expect(order.ship_address.address1).to eq ship_address_attrs["address1"]
        expect(order.ship_address.phone).to eq ship_address_attrs["phone"]
      end

      context "but the shipping method is being changed to one that requires a ship_address" do
        let(:new_shipping_method) { create(:shipping_method, require_ship_address: true) }
        before { params.merge!(shipping_method_id: new_shipping_method.id) }

        it "updates ship_address attrs" do
          standing_order.assign_attributes(params)
          expect(updater.update!).to be true
          expect(updater.order_update_issues.keys).to_not include order.id
          order.reload;
          expect(order.ship_address.firstname).to eq "Ship"
          expect(order.ship_address.lastname).to eq ship_address_attrs["lastname"]
          expect(order.ship_address.address1).to eq "123 abc st"
          expect(order.ship_address.phone).to eq "1123581321"
        end
      end
    end

    context "when a ship address is required" do
      before { shipping_method.update_attributes(require_ship_address: true) }

      context "when the ship address on the order matches that on the standing order" do
        it "updates ship_address attrs" do
          standing_order.assign_attributes(params)
          expect(updater.update!).to be true
          expect(updater.order_update_issues.keys).to_not include order.id
          order.reload;
          expect(order.ship_address.firstname).to eq "Ship"
          expect(order.ship_address.lastname).to eq ship_address_attrs["lastname"]
          expect(order.ship_address.address1).to eq "123 abc st"
          expect(order.ship_address.phone).to eq "1123581321"
        end
      end

      context "when the ship address on the order doesn't match that on the standing order" do
        before { order.ship_address.update_attributes(firstname: "Jane") }
        it "does not update ship_address on the order" do
          standing_order.assign_attributes(params)
          expect(updater.update!).to be true
          expect(updater.order_update_issues.keys).to include order.id
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
    let(:standing_order) { create(:standing_order, with_items: true, with_proxy_orders: true) }
    let(:order) { standing_order.proxy_orders.first.initialise_order! }
    let(:sli) { standing_order.standing_line_items.first }
    let(:variant) { sli.variant }

    before { variant.update_attribute(:count_on_hand, 2) }

    context "when quantity is within available stock" do
      let(:params) { { standing_line_items_attributes: [{ id: sli.id, quantity: 2}] } }
      let(:updater) { StandingOrderUpdater.new(standing_order) }

      it "updates the line_item quantities and totals on all orders" do
        expect(order.reload.total.to_f).to eq 59.97
        standing_order.assign_attributes(params)
        expect(updater.update!).to be true
        line_items = Spree::LineItem.where(order_id: standing_order.orders, variant_id: sli.variant_id)
        expect(line_items.map(&:quantity)).to eq [2]
        expect(order.reload.total.to_f).to eq 79.96
      end
    end

    context "when quantity is greater than available stock" do
      let(:params) { { standing_line_items_attributes: [{ id: sli.id, quantity: 3}] } }
      let(:updater) { StandingOrderUpdater.new(standing_order) }

      it "updates the line_item quantities and totals on all orders" do
        expect(order.reload.total.to_f).to eq 59.97
        standing_order.assign_attributes(params)
        expect(updater.update!).to be true
        line_items = Spree::LineItem.where(order_id: standing_order.orders, variant_id: sli.variant_id)
        expect(line_items.map(&:quantity)).to eq [3]
        expect(order.reload.total.to_f).to eq 99.95
      end
    end

    context "where the quantity of the item on an initialised order has already been changed" do
      let(:params) { { standing_line_items_attributes: [{ id: sli.id, quantity: 3}] } }
      let(:updater) { StandingOrderUpdater.new(standing_order) }
      let(:changed_line_item) { order.line_items.find_by_variant_id(sli.variant_id) }

      before { variant.update_attribute(:count_on_hand, 3) }

      context "when the changed line_item quantity matches the new quantity on the standing line item" do
        before { changed_line_item.update_attributes(quantity: 3) }

        it "does not change the quantity, and doesn't add the order to order_update_issues" do
          expect(order.reload.total.to_f).to eq 99.95
          standing_order.assign_attributes(params)
          expect(updater.update!).to be true
          expect(changed_line_item.reload.quantity).to eq 3
          expect(order.reload.total.to_f).to eq 99.95
          expect(updater.order_update_issues[order.id]).to be nil
        end
      end

      context "when the changed line_item quantity doesn't match the new quantity on the standing line item" do
        before { changed_line_item.update_attributes(quantity: 2) }

        it "does not change the quantity, and adds the order to order_update_issues" do
          expect(order.reload.total.to_f).to eq 79.96
          standing_order.assign_attributes(params)
          expect(updater.update!).to be true
          expect(changed_line_item.reload.quantity).to eq 2
          expect(order.reload.total.to_f).to eq 79.96
          expect(updater.order_update_issues[order.id]).to include "#{changed_line_item.product.name} - #{changed_line_item.full_name}"
        end
      end
    end
  end

  describe "adding a new line item" do
    let(:standing_order) { create(:standing_order, with_items: true, with_proxy_orders: true) }
    let(:order) { standing_order.proxy_orders.first.initialise_order! }
    let(:variant) { create(:variant) }
    let(:params) { { standing_line_items_attributes: [{ id: nil, variant_id: variant.id, quantity: 1}] } }
    let(:updater) { StandingOrderUpdater.new(standing_order) }

    it "adds the line item and updates the total on all orders" do
      expect(order.reload.total.to_f).to eq 59.97
      standing_order.assign_attributes(params)
      expect(updater.update!).to be true
      line_items = Spree::LineItem.where(order_id: standing_order.orders, variant_id: variant.id)
      expect(line_items.map(&:quantity)).to eq [1]
      expect(order.reload.total.to_f).to eq 79.96
    end
  end

  describe "removing an existing line item" do
    let(:standing_order) { create(:standing_order, with_items: true, with_proxy_orders: true) }
    let(:order) { standing_order.proxy_orders.first.initialise_order! }
    let(:sli) { standing_order.standing_line_items.first }
    let(:variant) { sli.variant }
    let(:params) { { standing_line_items_attributes: [{ id: sli.id, _destroy: true }] } }
    let(:updater) { StandingOrderUpdater.new(standing_order) }

    it "removes the line item and updates totals on all orders" do
      expect(order.reload.total.to_f).to eq 59.97
      standing_order.assign_attributes(params)
      expect(updater.update!).to be true
      line_items = Spree::LineItem.where(order_id: standing_order.orders, variant_id: variant.id)
      expect(line_items.count).to be 0
      expect(order.reload.total.to_f).to eq 39.98
    end
  end
end
