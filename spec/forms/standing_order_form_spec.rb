module OpenFoodNetwork
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
        form.save

        expect(standing_order.orders.count).to be 2

        # This order cycle has already closed, so no order is initialized
        order1 = standing_order.orders.find_by_order_cycle_id(order_cycle1.id)
        expect(order1).to be nil

        # Currently open order cycle, closing after begins_at and before ends_at
        # Note: Quantity for variant3 is 3, despite available stock being 1
        order2 = standing_order.orders.find_by_order_cycle_id(order_cycle2.id)
        expect(order2).to be_a Spree::Order
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
        # Note: Quantity for variant3 is 3, despite available stock being 1
        order3 = standing_order.orders.find_by_order_cycle_id(order_cycle3.id)
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
        order4 = standing_order.orders.find_by_order_cycle_id(order_cycle4.id)
        expect(order4).to be nil
      end
    end

    describe "making a change that causes an error" do
      let(:standing_order) { create(:standing_order_with_items) }
      let(:shipping_method) { standing_order.shipping_method }
      let(:invalid_shipping_method) { create(:shipping_method, distributors: [create(:enterprise)]) }
      let(:order) { standing_order.orders.first }
      let(:params) { { shipping_method_id: invalid_shipping_method.id } }
      let(:form) { StandingOrderForm.new(standing_order, params) }

      before do
        form.send(:initialise_orders!)
        form.save
      end

      it "does not update standing_order or associated orders" do
        expect(order.shipping_method).to eq shipping_method
        expect(order.shipments.first.shipping_method).to eq shipping_method
        expect(form.json_errors.keys).to eq [:shipping_method]
      end
    end

    describe "changing the shipping method" do
      let(:standing_order) { create(:standing_order_with_items) }
      let(:shipping_method) { standing_order.shipping_method }
      let(:new_shipping_method) { create(:shipping_method, distributors: [standing_order.shop]) }
      let(:order) { standing_order.orders.first }
      let(:params) { { shipping_method_id: new_shipping_method.id } }
      let(:form) { StandingOrderForm.new(standing_order, params) }

      context "when the shipping method on an order is the same as the standing order" do
        before { form.send(:initialise_orders!) }

        it "updates the shipping_method on the order and on shipments" do
          expect(order.shipments.first.shipping_method).to eq shipping_method
          form.save
          expect(order.shipping_method).to eq new_shipping_method
          expect(order.shipments.first.shipping_method).to eq new_shipping_method
        end
      end

      context "when the shipping method on a shipment is not the same as the standing order" do
        let(:changed_shipping_method) { create(:shipping_method) }

        before do
          form.send(:initialise_orders!)
          # Updating the shipping method on a shipment updates the shipping method on the order,
          # and vice-versa via logic in Spree's shipments controller. So updating both here mimics that
          # behaviour.
          order.shipments.first.update_attributes(shipping_method_id: changed_shipping_method.id)
          order.update_attributes(shipping_method_id: changed_shipping_method.id)
          form.save
        end

        it "does not update the shipping_method on the standing order or on the pre-altered shipment" do
          expect(order.reload.shipping_method).to eq changed_shipping_method
          expect(order.reload.shipments.first.shipping_method).to eq changed_shipping_method
        end
      end
    end

    describe "changing the payment method" do
      let(:standing_order) { create(:standing_order_with_items) }
      let(:order) { standing_order.orders.first }
      let(:payment_method) { standing_order.payment_method }
      let(:new_payment_method) { create(:payment_method, distributors: [standing_order.shop]) }
      let(:params) { { payment_method_id: new_payment_method.id } }
      let(:form) { StandingOrderForm.new(standing_order, params) }

      context "when the payment method on an order is the same as the standing order" do
        before { form.send(:initialise_orders!) }

        it "voids existing payments and creates a new payment with the relevant payment method" do
          expect(order.payments.reload.first.payment_method).to eq payment_method
          form.save
          payments = order.reload.payments
          expect(payments.count).to be 2
          expect(payments.with_state('void').count).to be 1
          expect(payments.with_state('checkout').count).to be 1
          expect(payments.with_state('void').first.payment_method).to eq payment_method
          expect(payments.with_state('checkout').first.payment_method).to eq new_payment_method
        end
      end

      context "when the payment method on a payment is not the same as the standing order" do
        let(:changed_payment_method) { create(:payment_method) }

        before do
          form.send(:initialise_orders!)
          order.payments.first.update_attribute(:payment_method_id, changed_payment_method.id)
          form.save
        end

        it "keeps pre-altered payments" do
          payments = order.reload.payments
          expect(payments.count).to be 1
          expect(payments.first.payment_method).to eq changed_payment_method
        end
      end
    end

    describe "changing begins_at" do
      let(:standing_order) { create(:standing_order_with_items, begins_at: Time.zone.now) }
      let(:params) { { begins_at: 1.year.from_now, ends_at: 2.years.from_now } }
      let(:form) { StandingOrderForm.new(standing_order, params) }

      before { form.send(:initialise_orders!) }

      it "removes orders outside the newly specified date range" do
        expect(standing_order.reload.orders.count).to be 1
        form.save
        expect(standing_order.reload.orders.count).to be 0
        form.params = { begins_at: 1.month.ago }
        form.save
        expect(standing_order.reload.orders.count).to be 1
      end
    end

    describe "changing the quantity of a line item" do
      let(:standing_order) { create(:standing_order_with_items) }
      let(:sli) { standing_order.standing_line_items.first }
      let(:params) { { standing_line_items_attributes: [ { id: sli.id, quantity: 4} ] } }
      let(:form) { StandingOrderForm.new(standing_order, params) }

      before { form.send(:initialise_orders!) }

      it "updates the line_item quantities and totals on all orders" do
        expect(standing_order.orders.first.reload.total.to_f).to eq 59.97
        form.save
        line_items = Spree::LineItem.where(order_id: standing_order.orders, variant_id: sli.variant_id)
        expect(line_items.map(&:quantity)).to eq [4]
        expect(standing_order.orders.first.reload.total.to_f).to eq 119.94
      end
    end

    describe "adding a new line item" do
      let!(:standing_order) { create(:standing_order_with_items) }
      let!(:variant) { create(:variant) }
      let!(:order_cycle) { standing_order.schedule.order_cycles.first }
      let!(:params) { { standing_line_items_attributes: [ { id: nil, variant_id: variant.id, quantity: 1} ] } }
      let!(:form) { StandingOrderForm.new(standing_order, params) }

      before do
        order_cycle.variants << variant
        form.send(:initialise_orders!)
      end

      it "add the line item and updates the total on all orders" do
        expect(standing_order.orders.first.reload.total.to_f).to eq 59.97
        form.save
        line_items = Spree::LineItem.where(order_id: standing_order.orders, variant_id: variant.id)
        expect(line_items.map(&:quantity)).to eq [1]
        expect(standing_order.orders.first.reload.total.to_f).to eq 79.96
      end
    end

    describe "removing an existing line item" do
      let(:standing_order) { create(:standing_order_with_items) }
      let(:sli) { standing_order.standing_line_items.first }
      let(:variant) { sli.variant}
      let(:params) { { standing_line_items_attributes: [ { id: sli.id, _destroy: true } ] } }
      let(:form) { StandingOrderForm.new(standing_order, params) }

      before { form.send(:initialise_orders!) }

      it "removes the line item and updates totals on all orders" do
        expect(standing_order.orders.first.reload.total.to_f).to eq 59.97
        form.save
        line_items = Spree::LineItem.where(order_id: standing_order.orders, variant_id: variant.id)
        expect(line_items.count).to be 0
        expect(standing_order.orders.first.reload.total.to_f).to eq 39.98
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
end
