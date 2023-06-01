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

  let(:charge) { build(:adjustment) }
  let(:variant) { build(:variant) }

  it 'is backordered if one of its inventory_units is backordered' do
    unit1 = create(:inventory_unit)
    unit2 = create(:inventory_unit)
    allow(unit1).to receive(:backordered?) { false }
    allow(unit2).to receive(:backordered?) { true }
    allow(shipment).to receive_messages(inventory_units: [unit1, unit2])
    expect(shipment).to be_backordered
  end

  context "display_cost" do
    it "retuns a Spree::Money" do
      allow(shipment).to receive(:cost) { 21.22 }
      expect(shipment.display_cost).to eq Spree::Money.new(21.22)
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

  context "manifest" do
    let(:order) { Spree::Order.create }
    let!(:variant) { create(:variant) }
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
        expect(shipment).to receive(:update_columns).
          with(state: 'shipped', updated_at: kind_of(Time))
        shipment.update!(order)
      end
    end

    shared_examples_for "pending if backordered" do
      it "should have a state of pending if backordered" do
        unit = create(:inventory_unit)
        allow(unit).to receive(:backordered?) { true }
        allow(shipment).to receive_messages(inventory_units: [unit])
        expect(shipment).to receive(:update_columns).
          with(state: 'pending', updated_at: kind_of(Time))
        shipment.update!(order)
      end
    end

    context "when order is canceled" do
      it "should result in a 'pending' state" do
        allow(order).to receive(:canceled?) { true }

        expect(shipment).to receive(:update_columns).
          with(state: 'canceled', updated_at: kind_of(Time))
        shipment.update!(order)
      end
    end

    context "when order cannot ship" do
      it "should result in a 'pending' state" do
        allow(order).to receive(:can_ship?) { false }

        expect(shipment).to receive(:update_columns).
          with(state: 'pending', updated_at: kind_of(Time))
        shipment.update!(order)
      end
    end

    context "when order can ship" do
      before { allow(order).to receive(:can_ship?) { true } }

      context "when order is paid" do
        before { allow(order).to receive(:paid?) { true } }

        it "should result in a 'ready' state" do
          expect(shipment).to receive(:update_columns).
            with(state: 'ready', updated_at: kind_of(Time))
          shipment.update!(order)
        end

        it_should_behave_like 'immutable once shipped'

        it_should_behave_like 'pending if backordered'

        context "when order has a credit owed" do
          before { allow(order).to receive(:payment_state) { 'credit_owed' } }

          it "should result in a 'ready' state" do
            shipment.state = 'pending'
            expect(shipment).to receive(:update_columns).
              with(state: 'ready', updated_at: kind_of(Time))
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
          expect(shipment).to receive(:update_columns).
            with(state: 'pending', updated_at: kind_of(Time))
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
        expect(shipment).to receive(:update_columns).
          with(state: 'shipped', updated_at: kind_of(Time))
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
      allow(shipment).to receive(:ensure_correct_adjustment)
      allow(shipment.order).to receive(:update_order!)

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
      allow(shipment).to receive(:ensure_correct_adjustment)
      allow(shipment.order).to receive(:update_order!)

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
      allow(shipment).to receive(:ensure_correct_adjustment)
      allow(shipment.order).to receive(:update_order!)

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
      allow(order).to receive(:update_order!)
      allow(shipment).to receive_messages(update_order: true, state: 'ready')
      allow(shipment).to receive_messages(fee_adjustment: charge)
      allow(shipping_method).to receive(:create_adjustment)
      allow(shipment).to receive(:ensure_correct_adjustment)
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

    it "should finalize the shipment's adjustment" do
      allow(shipment).to receive(:send_shipped_email)
      shipment.ship!
      expect(shipment.fee_adjustment.state).to eq 'finalized'
      expect(shipment.fee_adjustment).to be_immutable
    end
  end

  context "#ready" do
    # Regression test for #2040
    it "cannot ready a shipment for an order if the order is unpaid" do
      allow(order).to receive_messages(paid?: false)
      assert !shipment.can_ready?
    end
  end

  context "ensure_correct_adjustment" do
    before do
      shipment.save
      allow(shipment).to receive(:reload)
    end

    it "should create adjustment when not present" do
      allow(shipment).to receive_messages(fee_adjustment: nil)
      allow(shipment).to receive_messages(selected_shipping_rate_id: 1)
      expect(shipping_method).to receive(:create_adjustment).with(shipment.adjustment_label,
                                                                  shipment, true, "open")
      shipment.__send__(:ensure_correct_adjustment)
    end

    it "should update originator when adjustment is present" do
      allow(shipment).
        to receive_messages(selected_shipping_rate: Spree::ShippingRate.new(cost: 10.00))
      adjustment = build(:adjustment)
      allow(shipment).to receive_messages(fee_adjustment: adjustment, update_columns: true)
      allow(adjustment).to receive(:open?) { true }
      expect(shipment.fee_adjustment).to receive(:originator=).with(shipping_method)
      expect(shipment.fee_adjustment).to receive(:label=).with(shipment.adjustment_label)
      expect(shipment.fee_adjustment).to receive(:amount=).with(10.00)
      allow(shipment.fee_adjustment).to receive(:save!)
      expect(shipment.fee_adjustment).to receive(:reload)
      shipment.__send__(:ensure_correct_adjustment)
    end

    it 'should not update amount if adjustment is not open?' do
      allow(shipment).
        to receive_messages(selected_shipping_rate: Spree::ShippingRate.new(cost: 10.00))
      adjustment = build(:adjustment)
      allow(shipment).to receive_messages(fee_adjustment: adjustment, update_columns: true)
      allow(adjustment).to receive(:open?) { false }
      expect(shipment.fee_adjustment).to receive(:originator=).with(shipping_method)
      expect(shipment.fee_adjustment).to receive(:label=).with(shipment.adjustment_label)
      expect(shipment.fee_adjustment).not_to receive(:amount=).with(10.00)
      allow(shipment.fee_adjustment).to receive(:save!)
      expect(shipment.fee_adjustment).to receive(:reload)
      shipment.__send__(:ensure_correct_adjustment)
    end
  end

  describe "#update_amounts" do
    it "persists the shipping cost from the shipping fee adjustment" do
      allow(shipment).to receive(:fee_adjustment) { double(:adjustment, amount: 10) }
      expect(shipment).to receive(:update_columns).with(cost: 10, updated_at: kind_of(Time))

      shipment.update_amounts
    end
  end

  context "after_save" do
    it "should run correct callbacks" do
      expect(shipment).to receive(:ensure_correct_adjustment)
      expect(shipment).to receive(:update_adjustments)
      shipment.run_callbacks(:save)
    end
  end

  context "currency" do
    it "returns the order currency" do
      expect(shipment.currency).to eq order.currency
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
