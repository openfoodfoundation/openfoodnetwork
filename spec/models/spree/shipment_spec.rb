# frozen_string_literal: true

require 'spec_helper'
require 'benchmark'

describe Spree::Shipment do
  let(:order) { build(:order) }
  let(:shipping_method) { build(:shipping_method, name: "UPS") }
  let(:shipment) do
    shipment = Spree::Shipment.new order: order
    allow(shipment).to receive_messages(shipping_method: shipping_method)
    shipment.state = 'pending'
    shipment
  end

  let(:variant) { build(:variant) }

  it 'is backordered if one of its inventory_units is backordered' do
    unit1 = create(:inventory_unit)
    unit2 = create(:inventory_unit)
    allow(unit1).to receive(:backordered?) { false }
    allow(unit2).to receive(:backordered?) { true }
    allow(shipment).to receive_messages(inventory_units: [unit1, unit2])
    expect(shipment).to be_backordered
  end

  context "display_amount" do
    it "retuns a Spree::Money" do
      allow(shipment).to receive(:cost) { 21.22 }
      expect(shipment.display_amount).to eq Spree::Money.new(21.22)
    end
  end

  context "display_final_price" do
    it "returns a Spree::Money" do
      allow(shipment).to receive(:final_price) { 21.22 }
      expect(shipment.display_final_price).to eq Spree::Money.new(21.22)
    end
  end

  context "display_item_cost" do
    it "retuns a Spree::Money" do
      allow(shipment).to receive(:item_cost) { 21.22 }
      expect(shipment.display_item_cost).to eq Spree::Money.new(21.22)
    end
  end

  it "#item_cost" do
    shipment = Spree::Shipment.new(
      order: build_stubbed(:order_with_totals, line_items: [build_stubbed(:line_item)])
    )
    expect(shipment.item_cost).to eql(10.0)
  end

  it "#tax_total with included taxes" do
    shipment = Spree::Shipment.new
    expect(shipment.tax_total).to eq(0)
    shipment.included_tax_total = 10
    expect(shipment.tax_total).to eq(10)
  end

  it "#tax_total with additional taxes" do
    shipment = Spree::Shipment.new
    expect(shipment.tax_total).to eq(0)
    shipment.additional_tax_total = 10
    expect(shipment.tax_total).to eq(10)
  end

  it "#final_price" do
    shipment = Spree::Shipment.new
    shipment.cost = 10
    shipment.included_tax_total = 1
    expect(shipment.final_price).to eq(11)
  end

  context "manifest" do
    let(:order) { Spree::Order.create }
    let(:variant) { create(:variant) }
    let!(:line_item) { order.contents.add variant }
    let!(:shipment) { order.create_proposed_shipments.first }

    it "returns variant expected" do
      expect(shipment.manifest.first.variant).to eq variant
    end

    context "variant was removed" do
      before { variant.product.destroy }

      it "still returns variant expected" do
        expect(shipment.manifest.first.variant).to eq variant
      end
    end

    describe "with soft-deleted products or variants" do
      let!(:product) { create(:product) }
      let!(:order) { create(:order, distributor: product.supplier) }

      context "when the variant is soft-deleted" do
        it "can still access the variant" do
          order.line_items.first.variant.delete

          variants = shipment.reload.manifest.map(&:variant).uniq
          expect(variants).to eq [order.line_items.first.variant]
        end
      end

      context "when the product is soft-deleted" do
        it "can still access the variant" do
          order.line_items.first.variant.delete

          variants = shipment.reload.manifest.map(&:variant)
          expect(variants).to eq [order.line_items.first.variant]
        end
      end
    end
  end

  context 'shipping_rates' do
    let(:shipment) { create(:shipment) }
    let(:shipping_method1) { create(:shipping_method) }
    let(:shipping_method2) { create(:shipping_method) }
    let(:shipping_rates) {
      [
        Spree::ShippingRate.new(shipping_method: shipping_method1, cost: 10.00, selected: true),
        Spree::ShippingRate.new(shipping_method: shipping_method2, cost: 20.00)
      ]
    }

    it 'returns shipping_method from selected shipping_rate' do
      shipment.shipping_rates.delete_all
      shipment.shipping_rates.create shipping_method: shipping_method1, cost: 10.00, selected: true
      expect(shipment.shipping_method).to eq shipping_method1
    end

    context 'refresh_rates' do
      let(:mock_estimator) { double('estimator', shipping_rates: shipping_rates) }

      it 'should request new rates, and maintain shipping_method selection' do
        expect(OrderManagement::Stock::Estimator).
          to receive(:new).with(shipment.order).and_return(mock_estimator)
        # The first call is for the original shippping method,
        #   the second call is for the shippping method after the Estimator was executed
        allow(shipment).to receive(:shipping_method).and_return(shipping_method2, shipping_method1)

        expect(shipment.refresh_rates).to eq shipping_rates
        expect(shipment.reload.selected_shipping_rate.shipping_method_id).to eq shipping_method2.id
      end

      it 'should handle no shipping_method selection' do
        expect(OrderManagement::Stock::Estimator).
          to receive(:new).with(shipment.order).and_return(mock_estimator)
        allow(shipment).to receive_messages(shipping_method: nil)
        expect(shipment.refresh_rates).to eq shipping_rates
        expect(shipment.reload.selected_shipping_rate).to_not be_nil
      end

      it 'should not refresh if shipment is shipped' do
        expect(OrderManagement::Stock::Estimator).not_to receive(:new)
        shipment.shipping_rates.delete_all
        allow(shipment).to receive_messages(shipped?: true)
        expect(shipment.refresh_rates).to eq []
      end

      context 'to_package' do
        it 'should use symbols for states when adding contents to package' do
          shipment = Spree::Shipment.new(order: build_stubbed(:order))
          allow(shipment).
            to receive_message_chain(
              :inventory_units,
              includes: [
                build_stubbed(
                  :inventory_unit,
                  shipment: shipment,
                  variant: build_stubbed(:variant),
                  state: 'on_hand'
                ),
                build_stubbed(
                  :inventory_unit,
                  shipment: shipment,
                  variant: build_stubbed(:variant),
                  state: 'backordered'
                )
              ]
            )
          package = shipment.to_package
          expect(package.on_hand.count).to eq 1
          expect(package.backordered.count).to eq 1
        end
      end
    end
  end

  context "#update!" do
    shared_examples_for "immutable once shipped" do
      it "should remain in shipped state once shipped" do
        shipment.state = 'shipped'
        expect(shipment).to receive(:update_column).with(:state, 'shipped')
        shipment.update!(order)
      end
    end

    shared_examples_for "pending if backordered" do
      it "should have a state of pending if backordered" do
        unit = create(:inventory_unit)
        allow(unit).to receive(:backordered?) { true }
        allow(shipment).to receive_messages(inventory_units: [unit])
        expect(shipment).to receive(:update_column).with(:state, 'pending')
        shipment.update!(order)
      end
    end

    context "when order is canceled" do
      it "should result in a 'pending' state" do
        allow(order).to receive(:canceled?) { true }

        expect(shipment).to receive(:update_column).with(:state, 'canceled')
        shipment.update!(order)
      end
    end

    context "when order cannot ship" do
      it "should result in a 'pending' state" do
        allow(order).to receive(:can_ship?) { false }

        expect(shipment).to receive(:update_column).with(:state, 'pending')
        shipment.update!(order)
      end
    end

    context "when order can ship" do
      before { allow(order).to receive(:can_ship?) { true } }

      context "when order is paid" do
        before { allow(order).to receive(:paid?) { true } }

        it "should result in a 'ready' state" do
          expect(shipment).to receive(:update_column).with(:state, 'ready')
          shipment.update!(order)
        end

        it_should_behave_like 'immutable once shipped'

        it_should_behave_like 'pending if backordered'

        context "when order has a credit owed" do
          before { allow(order).to receive(:payment_state) { 'credit_owed' } }

          it "should result in a 'ready' state" do
            shipment.state = 'pending'
            expect(shipment).to receive(:update_column).with(:state, 'ready')
            shipment.update!(order)
          end

          it_should_behave_like 'immutable once shipped'

          it_should_behave_like 'pending if backordered'
        end
      end

      context "when order has balance due" do
        before { allow(order).to receive(:paid?) { false } }

        it "should result in a 'pending' state" do
          shipment.state = 'ready'
          expect(shipment).to receive(:update_column).with(:state, 'pending')
          shipment.update!(order)
        end

        it_should_behave_like 'immutable once shipped'

        it_should_behave_like 'pending if backordered'
      end
    end

    context "when shipment state changes to shipped" do
      it "should call after_ship" do
        shipment.state = 'pending'
        expect(shipment).to receive :after_ship
        allow(shipment).to receive_messages determine_state: 'shipped'
        expect(shipment).to receive(:update_column).with(:state, 'shipped')
        shipment.update!(order)
      end
    end
  end

  context "when order is completed" do
    before do
      allow(order).to receive_messages completed?: true
      allow(order).to receive_messages canceled?: false
    end

    it "should validate with inventory" do
      shipment.inventory_units = [create(:inventory_unit)]
      expect(shipment.valid?).to be_truthy
    end
  end

  context "#cancel" do
    it 'cancels the shipment' do
      allow(shipment.order).to receive(:update!)

      shipment.state = 'pending'
      expect(shipment).to receive(:after_cancel)
      shipment.cancel!
      expect(shipment.state).to eq 'canceled'
    end

    it 'restocks the items' do
      unit = double(:inventory_unit, variant: variant)
      allow(unit).to receive(:quantity) { 1 }
      allow(shipment).to receive_message_chain(:inventory_units,
                                               :group_by,
                                               map: [unit])
      shipment.stock_location = build(:stock_location)
      expect(shipment.stock_location).to receive(:restock).with(variant, 1, shipment)
      shipment.after_cancel
    end
  end

  context "#resume" do
    it 'will determine new state based on order' do
      allow(shipment.order).to receive(:update!)

      shipment.state = 'canceled'
      expect(shipment).to receive(:determine_state).and_return(:ready)
      expect(shipment).to receive(:after_resume)
      shipment.resume!
      expect(shipment.state).to eq 'ready'
    end

    it 'unstocks the items' do
      unit = create(:inventory_unit, variant: variant)
      allow(unit).to receive(:quantity) { 1 }
      allow(shipment).to receive_message_chain(:inventory_units,
                                               :group_by,
                                               map: [unit])
      shipment.stock_location = create(:stock_location)
      expect(shipment.stock_location).to receive(:unstock).with(variant, 1, shipment)
      shipment.after_resume
    end

    it 'will determine new state based on order' do
      allow(shipment.order).to receive(:update!)

      shipment.state = 'canceled'
      expect(shipment).to receive(:determine_state).twice.and_return('ready')
      expect(shipment).to receive(:after_resume)
      shipment.resume!
      # Shipment is pending because order is already paid
      expect(shipment.state).to eq 'pending'
    end
  end

  context "#ship" do
    before do
      allow(order).to receive(:update!)
      allow(shipment).to receive_messages(state: 'ready')
    end

    it "should update shipped_at timestamp" do
      allow(shipment).to receive(:send_shipped_email)
      shipment.ship!
      expect(shipment.shipped_at).to_not be_nil
      # Ensure value is persisted
      shipment.reload
      expect(shipment.shipped_at).to_not be_nil
    end

    it "should send a shipment email" do
      mail_message = double 'Mail::Message'
      shipment_id = nil
      expect(Spree::ShipmentMailer).to receive(:shipped_email) { |*args|
        shipment_id = args[0]
        mail_message
      }
      expect(mail_message).to receive :deliver_later
      shipment.ship!
      expect(shipment_id).to eq shipment.id
    end

    it "finalizes adjustments" do
      allow(shipment).to receive(:send_shipped_email)
      shipment.adjustments.each do |adjustment|
        expect(adjustment).to receive(:finalize!)
      end
      shipment.ship!
    end
  end

  context "#ready" do
    # Regression test for #2040
    it "cannot ready a shipment for an order if the order is unpaid" do
      allow(order).to receive_messages(paid?: false)
      assert !shipment.can_ready?
    end
  end

  context "updates cost when selected shipping rate is present" do
    let(:shipment) { create(:shipment) }

    before { allow(shipment).to receive_message_chain :selected_shipping_rate, cost: 5 }

    it "updates shipment totals" do
      shipment.update_amounts
      expect(shipment.reload.cost).to eq 5
    end

    it "factors in additional adjustments to adjustment total" do
      shipment.adjustments.create!({
                                     label: "Additional",
                                     amount: 5,
                                     included: false,
                                     state: "closed"
                                   })
      shipment.update_amounts
      expect(shipment.reload.adjustment_total).to eq 5
    end

    it "does not factor in included adjustments to adjustment total" do
      shipment.adjustments.create!({
                                     label: "Included",
                                     amount: 5,
                                     included: true,
                                     state: "closed"
                                   })
      shipment.update_amounts
      expect(shipment.reload.adjustment_total).to eq 0
    end
  end

  context "changes shipping rate via general update" do
    let(:order) do
      Spree::Order.create(
        payment_total: 100, payment_state: 'paid', total: 100, item_total: 100
      )
    end

    let(:shipment) { Spree::Shipment.create order_id: order.id }

    let(:shipping_rate) do
      Spree::ShippingRate.create shipment_id: shipment.id, cost: 10
    end

    before do
      shipment.update_attributes_and_order selected_shipping_rate_id: shipping_rate.id
    end

    it "updates everything around order shipment total and state" do
      expect(shipment.cost.to_f).to eq 10
      expect(shipment.state).to eq 'pending'
      expect(shipment.order.total.to_f).to eq 110
      expect(shipment.order.payment_state).to eq 'balance_due'
    end
  end

  context "after_save" do
    it "updates a linked adjustment" do
      pending "not sure when and if shipment adjustments are recalculated"
      # Need a persisted order for this
      shipment.order = create(:order)
      tax_rate = create(:tax_rate, amount: 10)
      adjustment = create(:adjustment, source: tax_rate)
      shipment.cost = 10
      shipment.adjustments << adjustment
      shipment.save
      expect(shipment.reload.adjustment_total).to eq 100
    end
  end

  context "currency" do
    it "returns the order currency" do
      expect(shipment.currency).to eq order.currency
    end
  end

  context "nil costs" do
    it "sets cost to 0" do
      shipment = Spree::Shipment.new
      shipment.valid?
      expect(shipment.cost).to eq 0
    end
  end

  context "#tracking_url" do
    it "uses shipping method to determine url" do
      expect(shipping_method).to receive(:build_tracking_url).with('1Z12345').and_return(:some_url)
      shipment.tracking = '1Z12345'

      expect(shipment.tracking_url).to eq :some_url
    end
  end

  context "set up new inventory units" do
    let(:variant) { double("Variant", id: 9) }
    let(:inventory_units) { double }
    let(:params) do
      { variant_id: variant.id, state: 'on_hand', order_id: order.id }
    end

    before { allow(shipment).to receive_messages inventory_units: inventory_units }

    it "associates variant and order" do
      expect(inventory_units).to receive(:create).with(params)
      unit = shipment.set_up_inventory('on_hand', variant, order)
    end
  end

  # Regression test for #3349
  context "#destroy" do
    it "destroys linked shipping_rates" do
      reflection = Spree::Shipment.reflect_on_association(:shipping_rates)
      reflection.options[:dependent] = :destroy
    end
  end
end
