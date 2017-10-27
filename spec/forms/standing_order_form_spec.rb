describe StandingOrderForm do
  describe "creating a new standing order" do
    let!(:shop) { create(:distributor_enterprise) }
    let!(:customer) { create(:customer, enterprise: shop) }
    let!(:product1) { create(:product, supplier: shop) }
    let!(:product2) { create(:product, supplier: shop) }
    let!(:product3) { create(:product, supplier: shop) }
    let!(:variant1) { create(:variant, product: product1, unit_value: '100', price: 12.00, option_values: []) }
    let!(:variant2) { create(:variant, product: product2, unit_value: '1000', price: 6.00, option_values: []) }
    let!(:variant3) { create(:variant, product: product2, unit_value: '1000', price: 2.50, option_values: [], count_on_hand: 1) }
    let!(:enterprise_fee) { create(:enterprise_fee, amount: 1.75) }
    let!(:order_cycle1) { create(:simple_order_cycle, coordinator: shop, orders_open_at: 9.days.ago, orders_close_at: 2.day.ago) }
    let!(:order_cycle2) { create(:simple_order_cycle, coordinator: shop, orders_open_at: 2.day.ago, orders_close_at: 5.days.from_now) }
    let!(:order_cycle3) { create(:simple_order_cycle, coordinator: shop, orders_open_at: 5.days.from_now, orders_close_at: 12.days.from_now) }
    let!(:order_cycle4) { create(:simple_order_cycle, coordinator: shop, orders_open_at: 12.days.from_now, orders_close_at: 19.days.from_now) }
    let!(:outgoing_exchange1) { order_cycle1.exchanges.create(sender: shop, receiver: shop, variants: [variant1, variant2, variant3], enterprise_fees: [enterprise_fee]) }
    let!(:outgoing_exchange2) { order_cycle2.exchanges.create(sender: shop, receiver: shop, variants: [variant1, variant2, variant3], enterprise_fees: [enterprise_fee]) }
    let!(:outgoing_exchange3) { order_cycle3.exchanges.create(sender: shop, receiver: shop, variants: [variant1, variant3], enterprise_fees: []) }
    let!(:outgoing_exchange4) { order_cycle4.exchanges.create(sender: shop, receiver: shop, variants: [variant1, variant2, variant3], enterprise_fees: [enterprise_fee]) }
    let!(:schedule) { create(:schedule, order_cycles: [order_cycle1, order_cycle2, order_cycle3, order_cycle4]) }
    let!(:payment_method) { create(:payment_method, distributors: [shop]) }
    let!(:shipping_method) { create(:shipping_method, distributors: [shop]) }
    let!(:address) { create(:address) }
    let(:standing_order) { StandingOrder.new }

    let!(:params) { {
      shop_id: shop.id,
      customer_id: customer.id,
      schedule_id: schedule.id,
      bill_address_attributes: address.clone.attributes,
      ship_address_attributes: address.clone.attributes,
      payment_method_id: payment_method.id,
      shipping_method_id: shipping_method.id,
      begins_at: 4.days.ago,
      ends_at: 14.days.from_now,
      standing_line_items_attributes: [
        {variant_id: variant1.id, quantity: 1},
        {variant_id: variant2.id, quantity: 2},
        {variant_id: variant3.id, quantity: 3}
      ]
    } }

    let(:form) { StandingOrderForm.new(standing_order, params) }

    it "creates orders for each order cycle in the schedule" do
      Spree::Config.set allow_backorders: false
      expect(form.save).to be true

      expect(standing_order.proxy_orders.count).to be 2

      # This order cycle has already closed, so no order is initialized
      proxy_order1 = standing_order.proxy_orders.find_by_order_cycle_id(order_cycle1.id)
      expect(proxy_order1).to be nil

      # Currently open order cycle, closing after begins_at and before ends_at
      proxy_order2 = standing_order.proxy_orders.find_by_order_cycle_id(order_cycle2.id)
      expect(proxy_order2).to be_a ProxyOrder
      order2 = proxy_order2.initialise_order!
      expect(order2.line_items.count).to be 3
      expect(order2.line_items.find_by_variant_id(variant3.id).quantity).to be 3
      expect(order2.shipments.count).to be 1
      expect(order2.shipments.first.shipping_method).to eq shipping_method
      expect(order2.payments.count).to be 1
      expect(order2.payments.first.payment_method).to eq payment_method
      expect(order2.payments.first.state).to eq 'checkout'
      expect(order2.total).to eq 42
      expect(order2.completed?).to be false

      # Future order cycle, closing after begins_at and before ends_at
      # Adds line items for variants that aren't yet available from the order cycle
      proxy_order3 = standing_order.proxy_orders.find_by_order_cycle_id(order_cycle3.id)
      expect(proxy_order3).to be_a ProxyOrder
      order3 = proxy_order3.initialise_order!
      expect(order3).to be_a Spree::Order
      expect(order3.line_items.count).to be 3
      expect(order2.line_items.find_by_variant_id(variant3.id).quantity).to be 3
      expect(order3.shipments.count).to be 1
      expect(order3.shipments.first.shipping_method).to eq shipping_method
      expect(order3.payments.count).to be 1
      expect(order3.payments.first.payment_method).to eq payment_method
      expect(order3.payments.first.state).to eq 'checkout'
      expect(order3.total).to eq 31.50
      expect(order3.completed?).to be false

      # Future order cycle closing after ends_at
      proxy_order4 = standing_order.proxy_orders.find_by_order_cycle_id(order_cycle4.id)
      expect(proxy_order4).to be nil
    end
  end

  describe "changing the shipping method" do
    let(:standing_order) { create(:standing_order, with_items: true, with_proxy_orders: true) }
    let(:order) { standing_order.proxy_orders.first.initialise_order! }
    let(:shipping_method) { standing_order.shipping_method }
    let(:new_shipping_method) { create(:shipping_method, distributors: [standing_order.shop]) }
    let(:invalid_shipping_method) { create(:shipping_method, distributors: [create(:enterprise)]) }
    let(:form) { StandingOrderForm.new(standing_order, params) }

    context "when the shipping method on an order is the same as the standing order" do
      let(:params) { { shipping_method_id: new_shipping_method.id } }

      context "and the shipping method is associated with the shop" do
        it "updates the shipping_method on the order and on shipments" do
          expect(order.shipments.first.shipping_method).to eq shipping_method
          expect(form.save).to be true
          expect(standing_order.reload.shipping_method).to eq new_shipping_method
          expect(order.reload.shipping_method).to eq new_shipping_method
          expect(order.shipments.first.shipping_method).to eq new_shipping_method
        end
      end

      context "and the shipping method is not associated with the shop" do
        let(:params) { { shipping_method_id: invalid_shipping_method.id } }

        it "returns false and does not update the shipping method on the order or shipments" do
          expect(order.shipments.first.shipping_method).to eq shipping_method
          expect(form.save).to be false
          expect(standing_order.reload.shipping_method).to eq shipping_method
          expect(order.reload.shipping_method).to eq shipping_method
          expect(order.shipments.first.shipping_method).to eq shipping_method
        end
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
          expect(form.save).to be true
        end

        it "does not update the shipping_method on the standing order or on the pre-altered shipment" do
          expect(order.reload.shipping_method).to eq new_shipping_method
          expect(order.reload.shipments.first.shipping_method).to eq new_shipping_method
          expect(form.order_update_issues[order.id]).to be nil
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
          expect(form.save).to be true
        end

        it "does not update the shipping_method on the standing order or on the pre-altered shipment" do
          expect(order.reload.shipping_method).to eq changed_shipping_method
          expect(order.reload.shipments.first.shipping_method).to eq changed_shipping_method
          expect(form.order_update_issues[order.id]).to include "Shipping Method"
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
    let(:form) { StandingOrderForm.new(standing_order, params) }

    context "when the payment method on an order is the same as the standing order" do
      let(:params) { { payment_method_id: new_payment_method.id } }

      context "and the submitted payment method is associated with the shop" do
        it "voids existing payments and creates a new payment with the relevant payment method" do
          expect(order.payments.reload.first.payment_method).to eq payment_method
          expect(form.save).to be true
          payments = order.reload.payments
          expect(payments.count).to be 2
          expect(payments.with_state('void').count).to be 1
          expect(payments.with_state('checkout').count).to be 1
          expect(payments.with_state('void').first.payment_method).to eq payment_method
          expect(payments.with_state('checkout').first.payment_method).to eq new_payment_method
        end
      end

      context "and the submitted shipping method is not associated with the shop" do
        let(:params) { { payment_method_id: invalid_payment_method.id } }

        it "returns false and does not void existing payments or create a new payment" do
          expect(order.payments.reload.first.payment_method).to eq payment_method
          expect(form.save).to be false
          payments = order.reload.payments
          expect(payments.count).to be 1
          expect(payments.with_state('void').count).to be 0
          expect(payments.with_state('checkout').count).to be 1
          expect(payments.with_state('checkout').first.payment_method).to eq payment_method
          expect(form.errors[:payment_method]).to include "is not available to #{standing_order.shop.name}"
        end
      end

      context "and the submitted shipping method is not associated with the shop" do
        let(:params) { { payment_method_id: bogus_payment_method.id } }

        it "returns false and does not void existing payments or create a new payment" do
          expect(order.payments.reload.first.payment_method).to eq payment_method
          expect(form.save).to be false
          payments = order.reload.payments
          expect(payments.count).to be 1
          expect(payments.with_state('void').count).to be 0
          expect(payments.with_state('checkout').count).to be 1
          expect(payments.with_state('checkout').first.payment_method).to eq payment_method
          expect(form.errors[:payment_method]).to include "must be a Cash or Stripe method"
        end
      end
    end

    context "when the payment method on a payment is not the same as the standing order" do
      let(:params) { { payment_method_id: new_payment_method.id } }

      context "when the payment method on a payment is the same as the original payment method on the standing order" do
        before do
          order.payments.first.update_attribute(:payment_method_id, new_payment_method.id)
          expect(form.save).to be true
        end

        it "keeps pre-altered payments and doesn't add an issue to order_update_issues" do
          payments = order.reload.payments
          expect(payments.count).to be 1
          expect(payments.first.payment_method).to eq new_payment_method
          expect(form.order_update_issues[order.id]).to be nil
        end
      end

      context "when the payment method on a shipment is not the same as the original payment method on the standing order" do
        let(:changed_payment_method) { create(:payment_method) }

        before do
          order.payments.first.update_attribute(:payment_method_id, changed_payment_method.id)
          expect(form.save).to be true
        end

        it "keeps pre-altered payments and adds an issue to order_update_issues" do
          payments = order.reload.payments
          expect(payments.count).to be 1
          expect(payments.first.payment_method).to eq changed_payment_method
          expect(form.order_update_issues[order.id]).to include "Payment Method"
        end
      end
    end
  end

  describe "changing begins_at" do
    let(:standing_order) { create(:standing_order, begins_at: Time.zone.now, ends_at: 2.months.from_now, with_items: true, with_proxy_orders: true) }
    let(:form) { StandingOrderForm.new(standing_order, params) }

    before { standing_order.proxy_orders.each(&:initialise_order!) }

    context "to a date that is before ends_at" do
      let(:params) { { begins_at: 1.month.from_now } }

      it "removes orders outside the newly specified date range, recreates proxy orders" do
        expect(standing_order.reload.proxy_orders.count).to be 1
        expect(standing_order.reload.orders.count).to be 1
        expect(form.save).to be true
        expect(standing_order.reload.proxy_orders.count).to be 0
        expect(standing_order.reload.orders.count).to be 0
        form.params = { begins_at: 1.month.ago }
        expect(form.save).to be true
        expect(standing_order.reload.proxy_orders.count).to be 1
        expect(standing_order.reload.orders.count).to be 0
      end
    end

    context "to a date that is after ends_at" do
      let(:params) { { begins_at: 3.months.from_now } }

      it "returns false, does not update begins_at and alter orders or proxy orders" do
        expect(standing_order.reload.proxy_orders.count).to be 1
        expect(standing_order.reload.orders.count).to be 1
        expect(form.save).to be false
        expect(standing_order.reload.begins_at).to be_within(5.seconds).of Time.now
        expect(standing_order.proxy_orders.count).to be 1
        expect(standing_order.orders.count).to be 1
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
    let(:form) { StandingOrderForm.new(standing_order, params) }

    context "when a ship address is not required" do
      before { shipping_method.update_attributes(require_ship_address: false) }

      context "when the bill_address on the order matches that on the standing order" do
        it "updates all bill_address attrs and ship_address names + phone" do
          expect(form.save).to be true
          expect(form.order_update_issues.keys).to_not include order.id
          order.reload; standing_order.reload;
          expect(standing_order.bill_address.firstname).to eq "Bill"
          expect(standing_order.bill_address.lastname).to eq bill_address_attrs["lastname"]
          expect(standing_order.bill_address.address1).to eq "123 abc st"
          expect(standing_order.bill_address.phone).to eq "1123581321"
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
          expect(form.save).to be true
          expect(form.order_update_issues.keys).to include order.id
          order.reload; standing_order.reload;
          expect(standing_order.bill_address.firstname).to eq "Bill"
          expect(standing_order.bill_address.lastname).to eq bill_address_attrs["lastname"]
          expect(standing_order.bill_address.address1).to eq "123 abc st"
          expect(standing_order.bill_address.phone).to eq "1123581321"
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
          expect(form.save).to be true
          expect(form.order_update_issues.keys).to_not include order.id
          order.reload; standing_order.reload;
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
          expect(form.save).to be true
          expect(form.order_update_issues.keys).to include order.id
          order.reload; standing_order.reload;
          expect(standing_order.bill_address.firstname).to eq "Bill"
          expect(standing_order.bill_address.lastname).to eq bill_address_attrs["lastname"]
          expect(standing_order.bill_address.address1).to eq "123 abc st"
          expect(standing_order.bill_address.phone).to eq "1123581321"
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
    let(:form) { StandingOrderForm.new(standing_order, params) }

    context "when a ship address is not required" do
      before { shipping_method.update_attributes(require_ship_address: false) }

      it "does not change the ship address" do
        expect(form.save).to be true
        expect(form.order_update_issues.keys).to_not include order.id
        order.reload; standing_order.reload;
        expect(order.ship_address.firstname).to eq ship_address_attrs["firstname"]
        expect(order.ship_address.lastname).to eq ship_address_attrs["lastname"]
        expect(order.ship_address.address1).to eq ship_address_attrs["address1"]
        expect(order.ship_address.phone).to eq ship_address_attrs["phone"]
      end

      context "but the shipping method is being changed to one that requires a ship_address" do
        let(:new_shipping_method) { create(:shipping_method, require_ship_address: true) }
        before { params.merge!({ shipping_method_id: new_shipping_method.id }) }

        it "updates ship_address attrs" do
          expect(form.save).to be true
          expect(form.order_update_issues.keys).to_not include order.id
          order.reload; standing_order.reload;
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
          expect(form.save).to be true
          expect(form.order_update_issues.keys).to_not include order.id
          order.reload; standing_order.reload;
          expect(standing_order.ship_address.firstname).to eq "Ship"
          expect(standing_order.ship_address.lastname).to eq ship_address_attrs["lastname"]
          expect(standing_order.ship_address.address1).to eq "123 abc st"
          expect(standing_order.ship_address.phone).to eq "1123581321"
          expect(order.ship_address.firstname).to eq "Ship"
          expect(order.ship_address.lastname).to eq ship_address_attrs["lastname"]
          expect(order.ship_address.address1).to eq "123 abc st"
          expect(order.ship_address.phone).to eq "1123581321"
        end
      end

      context "when the ship address on the order doesn't match that on the standing order" do
        before { order.ship_address.update_attributes(firstname: "Jane") }
        it "does not update ship_address on the order" do
          expect(form.save).to be true
          expect(form.order_update_issues.keys).to include order.id
          order.reload; standing_order.reload;
          expect(standing_order.ship_address.firstname).to eq "Ship"
          expect(standing_order.ship_address.lastname).to eq ship_address_attrs["lastname"]
          expect(standing_order.ship_address.address1).to eq "123 abc st"
          expect(standing_order.ship_address.phone).to eq "1123581321"
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
      let(:params) { { standing_line_items_attributes: [ { id: sli.id, quantity: 2} ] } }
      let(:form) { StandingOrderForm.new(standing_order, params) }

      it "updates the line_item quantities and totals on all orders" do
        expect(order.reload.total.to_f).to eq 59.97
        expect(form.save).to be true
        line_items = Spree::LineItem.where(order_id: standing_order.orders, variant_id: sli.variant_id)
        expect(line_items.map(&:quantity)).to eq [2]
        expect(order.reload.total.to_f).to eq 79.96
      end
    end

    context "when quantity is greater than available stock" do
      let(:params) { { standing_line_items_attributes: [ { id: sli.id, quantity: 3} ] } }
      let(:form) { StandingOrderForm.new(standing_order, params) }

      it "updates the line_item quantities and totals on all orders" do
        expect(order.reload.total.to_f).to eq 59.97
        expect(form.save).to be true
        line_items = Spree::LineItem.where(order_id: standing_order.orders, variant_id: sli.variant_id)
        expect(line_items.map(&:quantity)).to eq [3]
        expect(order.reload.total.to_f).to eq 99.95
      end
    end

    context "where the quantity of the item on an initialised order has already been changed" do
      let(:params) { { standing_line_items_attributes: [ { id: sli.id, quantity: 3} ] } }
      let(:form) { StandingOrderForm.new(standing_order, params) }
      let(:changed_line_item) { order.line_items.find_by_variant_id(sli.variant_id) }

      before { variant.update_attribute(:count_on_hand, 3) }

      context "when the changed line_item quantity matches the new quantity on the standing line item" do
        before { changed_line_item.update_attributes(quantity: 3) }

        it "does not change the quantity, and doesn't add the order to order_update_issues" do
          expect(order.reload.total.to_f).to eq 99.95
          expect(form.save).to be true
          expect(changed_line_item.reload.quantity).to eq 3
          expect(order.reload.total.to_f).to eq 99.95
          expect(form.order_update_issues[order.id]).to be nil
        end
      end

      context "when the changed line_item quantity doesn't match the new quantity on the standing line item" do
        before { changed_line_item.update_attributes(quantity: 2) }

        it "does not change the quantity, and adds the order to order_update_issues" do
          expect(order.reload.total.to_f).to eq 79.96
          expect(form.save).to be true
          expect(changed_line_item.reload.quantity).to eq 2
          expect(order.reload.total.to_f).to eq 79.96
          expect(form.order_update_issues[order.id]).to include "#{changed_line_item.product.name} - #{changed_line_item.full_name}"
        end
      end
    end
  end

  describe "adding a new line item" do
    let(:variant) { create(:variant) }
    let(:unavailable_variant) { create(:variant) }
    let(:shop) { create(:enterprise) }
    let(:order_cycle) { create(:simple_order_cycle, variants: [variant], coordinator: shop, distributors: [shop]) }
    let(:schedule) { create(:schedule, order_cycles: [order_cycle] )}
    let(:standing_order) { create(:standing_order, schedule: schedule, shop: shop, with_items: true, with_proxy_orders: true) }
    let(:order) { standing_order.proxy_orders.first.initialise_order! }
    let(:form) { StandingOrderForm.new(standing_order, params) }

    context "that is available from the selected schedule" do
      let(:params) { { standing_line_items_attributes: [ { id: nil, variant_id: variant.id, quantity: 1} ] } }

      it "adds the line item and updates the total on all orders" do
        expect(order.reload.total.to_f).to eq 59.97
        expect(form.save).to be true
        line_items = Spree::LineItem.where(order_id: standing_order.orders, variant_id: variant.id)
        expect(line_items.map(&:quantity)).to eq [1]
        expect(order.reload.total.to_f).to eq 79.96
      end
    end

    context "that is not available from the selected schedule" do
      let(:params) { { standing_line_items_attributes: [ { id: nil, variant_id: unavailable_variant.id, quantity: 1} ] } }

      it "returns false and does not add the line item or update the total on orders" do
        expect(order.reload.total.to_f).to eq 59.97
        expect(form.save).to be false
        line_items = Spree::LineItem.where(order_id: standing_order.orders, variant_id: variant.id)
        expect(line_items.count).to be 0
        expect(order.reload.total.to_f).to eq 59.97
        expect(form.json_errors.keys).to eq [:standing_line_items]
      end
    end
  end

  describe "removing an existing line item" do
    let(:standing_order) { create(:standing_order, with_items: true, with_proxy_orders: true) }
    let(:order) { standing_order.proxy_orders.first.initialise_order! }
    let(:sli) { standing_order.standing_line_items.first }
    let(:variant) { sli.variant}
    let(:params) { { standing_line_items_attributes: [ { id: sli.id, _destroy: true } ] } }
    let(:form) { StandingOrderForm.new(standing_order, params) }

    context "that is not the last remaining item" do
      it "removes the line item and updates totals on all orders" do
        expect(order.reload.total.to_f).to eq 59.97
        expect(form.save).to be true
        line_items = Spree::LineItem.where(order_id: standing_order.orders, variant_id: variant.id)
        expect(line_items.count).to be 0
        expect(order.reload.total.to_f).to eq 39.98
      end
    end

    context "that is the last remaining item" do
      before do
        standing_order.standing_line_items.where('variant_id != ?',variant.id).destroy_all
        order.line_items.where('variant_id != ?',variant.id).destroy_all
        standing_order.reload
        order.reload
      end

      it "returns false and does not remove the line item or update totals on orders" do
        expect(order.reload.total.to_f).to eq 19.99
        expect(form.save).to be false
        line_items = Spree::LineItem.where(order_id: standing_order.orders, variant_id: variant.id)
        expect(line_items.count).to be 1
        expect(order.reload.total.to_f).to eq 19.99
        expect(form.json_errors.keys).to eq [:standing_line_items]
      end
    end
  end

  describe "validating price_estimates on standing line items" do
    let(:params) { { } }
    let(:form) { StandingOrderForm.new(nil, params) }

    context "when line_item params are present" do
      before { allow(form).to receive(:price_estimate_for) }

      it "does nothing" do
        form.send(:validate_price_estimates)
        expect(form.params[:standing_line_items_attributes]).to be nil
      end
    end

    context "when line_item params are present" do
      before do
        params[:standing_line_items_attributes] = [ { id: 1, price_estimate: 2.50 }, { id: 2, price_estimate: 3.50 }]
      end

      context "when no fee calculator is present" do
        before { allow(form).to receive(:price_estimate_for) }

        it "clears price estimates on all standing line item attributes" do
          form.send(:validate_price_estimates)
          attrs = form.params[:standing_line_items_attributes]
          expect(attrs.first.keys).to_not include :price_estimate
          expect(attrs.last.keys).to_not include :price_estimate
          expect(form).to_not have_received(:price_estimate_for)
        end
      end

      context "when a fee calculator is present" do
        let(:variant) { create(:variant) }
        let(:fee_calculator) { double(:fee_calculator) }

        before do
          allow(form).to receive(:fee_calculator) { fee_calculator }
          allow(form).to receive(:price_estimate_for) { 5.30 }
          params[:standing_line_items_attributes].first[:variant_id] = variant.id
        end

        it "clears price estimates on standing line item attributes without variant ids" do
          form.send(:validate_price_estimates)
          attrs = form.params[:standing_line_items_attributes]
          expect(attrs.first.keys).to include :price_estimate
          expect(attrs.last.keys).to_not include :price_estimate
          expect(attrs.first[:price_estimate]).to eq 5.30
          expect(form).to have_received(:price_estimate_for).with(variant)
        end
      end
    end
  end
end
