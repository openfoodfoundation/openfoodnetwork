# frozen_string_literal: true

RSpec.describe OrderManagement::Order::Updater do
  let(:order) { create(:order) }
  let(:updater) { OrderManagement::Order::Updater.new(order) }

  describe "#update_totals" do
    before do
      2.times { create(:line_item, order:, price: 10) }
    end

    it "updates payment totals" do
      allow(order).to receive_message_chain(:payments, :completed, :sum).and_return(10)

      updater.update_totals
      expect(order.payment_total).to eq(10)
    end
  end

  describe "#update_item_total" do
    before do
      2.times { create(:line_item, order:, price: 10) }
    end

    it "updates item total" do
      updater.update_item_total
      expect(order.item_total).to eq(20)
    end
  end

  describe "#update_adjustment_total" do
    before do
      2.times { create(:line_item, order:, price: 10) }
    end

    it "updates adjustment totals" do
      allow(order).to receive_message_chain(:all_adjustments, :additional, :eligible,
                                            :sum).and_return(-5)
      allow(order).to receive_message_chain(:all_adjustments, :tax, :additional,
                                            :sum).and_return(20)
      allow(order).to receive_message_chain(:all_adjustments, :tax, :inclusive,
                                            :sum).and_return(15)

      updater.update_adjustment_total
      expect(order.adjustment_total).to eq(-5)
      expect(order.additional_tax_total).to eq(20)
      expect(order.included_tax_total).to eq(15)
    end
  end

  describe "#update_shipment_state" do
    let(:shipment) { build(:shipment) }

    before do
      allow(order).to receive(:shipments).and_return([shipment])
    end

    it "is backordered" do
      allow(shipment).to receive(:backordered?) { true }
      updater.update_shipment_state

      expect(order.shipment_state).to eq 'backorder'
    end

    it "is nil" do
      allow(shipment).to receive(:state).and_return(nil)

      updater.update_shipment_state
      expect(order.shipment_state).to be_nil
    end

    ["shipped", "ready", "pending", "canceled"].each do |state|
      it "is #{state}" do
        allow(shipment).to receive(:state).and_return(state)
        updater.update_shipment_state
        expect(order.shipment_state).to eq state.to_s
      end
    end
  end

  it "state change" do
    order = create(:order)
    order.shipment_state = 'shipped'
    state_changes = double
    allow(order).to receive(:state_changes) { state_changes }
    expect(state_changes).to receive(:create).with(
      previous_state: nil,
      next_state: 'shipped',
      name: 'shipment',
      user_id: order.user_id
    )

    order.state_changed('shipment')
  end

  describe "#update" do
    it "updates totals once" do
      expect(updater).to receive(:update_totals).once
      updater.update
    end

    it "updates all adjustments" do
      expect(updater).to receive(:update_all_adjustments)
      updater.update
    end

    context "completed order" do
      before { allow(order).to receive(:completed?) { true } }

      it "updates payment state" do
        expect(updater).to receive(:update_payment_state)
        updater.update
      end

      it "updates shipment state" do
        expect(updater).to receive(:update_shipment_state)
        updater.update
      end

      context "with pending payments" do
        let(:order) { create(:completed_order_with_totals) }

        it "updates pending payments" do
          payment = create(:payment, order:, amount: order.total)

          # update order so the order total will change
          update_order_quantity(order)
          order.payments.reload

          expect { updater.update }.to change { payment.reload.amount }.from(50).to(60)
        end
      end
    end

    context "incompleted order" do
      before { allow(order).to receive_messages completed?: false }

      it "doesnt update payment state" do
        expect(updater).not_to receive(:update_payment_state)
        updater.update
      end

      it "doesnt update shipment state" do
        expect(updater).not_to receive(:update_shipment_state)
        updater.update
      end

      it "doesnt update the order shipment" do
        shipment = build(:shipment)
        allow(order).to receive_messages shipments: [shipment]

        expect(shipment).not_to receive(:update!).with(order)
        expect(updater).not_to receive(:update_shipments).with(order)
        updater.update
      end

      context "with pending payments" do
        let!(:payment) { create(:payment, order:, amount: order.total) }

        context "with order in payment state" do
          let(:order) { create(:order_with_totals, state: "payment") }

          it "updates pending payments" do
            # update order so the order total will change
            update_order_quantity(order)
            order.payments.reload

            expect { updater.update }.to change { payment.reload.amount }.from(10).to(20)
          end
        end

        context "with order in confirmation state" do
          let(:order) { create(:order_with_totals, state: "confirmation") }

          it "updates pending payments" do
            # update order so the order total will change
            update_order_quantity(order)
            order.payments.reload

            expect { updater.update }.to change { payment.reload.amount }.from(10).to(20)
          end

          it "updates pending payments fees" do
            calculator = build(:calculator_flat_percent_per_item, preferred_flat_percent: 10)
            payment_method = create(:payment_method, name: "Percentage cash", calculator:)
            payment = create(:payment, payment_method:, order:, amount: order.total)

            # update order so the order total will change
            update_order_quantity(order)
            order.payments.reload

            expect { updater.update }.to change { payment.reload.amount }.from(10).to(22)
              .and change { payment.reload.adjustment.amount }.from(1).to(2)
          end
        end

        context "with order in cart" do
          let(:order) { create(:order_with_totals) }

          it "doesn't update pending payments" do
            # update order so the order total will change
            update_order_quantity(order)

            expect { updater.update }.not_to change { payment.reload.amount }
          end
        end
      end
    end
  end

  describe "#update_shipments" do
    before { allow(order).to receive(:completed?) { true } }

    it "updates the order shipment" do
      shipment = build(:shipment)
      allow(order).to receive_messages shipments: [shipment]

      expect(shipment).to receive(:update!).with(order)
      updater.update_shipments
    end
  end

  describe "#update_payment_state" do
    context "when the order has no valid payments" do
      it "is failed" do
        allow(order).to receive_message_chain(:payments, :valid, :empty?).and_return(true)

        updater.update_payment_state
        expect(order.payment_state).to eq('failed')
      end
    end

    context "when the order has a payment that requires authorization" do
      let!(:payment) { create(:payment, order:, state: "requires_authorization") }

      it "returns requires_authorization" do
        expect {
          updater.update_payment_state
        }.to change { order.payment_state }.to 'requires_authorization'
      end
    end

    context "when order has a payment that requires authorization and a completed payment" do
      let!(:payment) { create(:payment, order:, state: "requires_authorization") }
      let!(:completed_payment) { create(:payment, :completed, order:) }

      it "returns paid" do
        updater.update_payment_state
        expect(order.payment_state).not_to eq("requires_authorization")
      end
    end

    context "payment total is greater than order total" do
      it "is credit_owed" do
        order.payment_total = 2
        order.total = 1

        expect {
          updater.update_payment_state
        }.to change { order.payment_state }.to 'credit_owed'
      end
    end

    context "order total is greater than payment total" do
      it "is credit_owed" do
        order.payment_total = 1
        order.total = 2

        expect {
          updater.update_payment_state
        }.to change { order.payment_state }.to 'balance_due'
      end
    end

    context "order total equals payment total" do
      it "is paid" do
        order.payment_total = 30
        order.total = 30

        expect {
          updater.update_payment_state
        }.to change { order.payment_state }.to 'paid'
      end
    end

    context "order is canceled" do
      before { order.state = 'canceled' }

      context "and is still unpaid" do
        it "is void" do
          order.payment_total = 0
          order.total = 30

          expect {
            updater.update_payment_state
          }.to change { order.payment_state }.to 'void'
        end
      end

      context "and is paid" do
        it "is credit_owed" do
          order.payment_total = 30
          order.total = 30
          allow(order).to receive_message_chain(:payments, :valid, :empty?) { false }
          allow(order).to receive_message_chain(:payments, :completed, :empty?) { false }
          allow(order).to receive_message_chain(:payments, :requires_authorization, :any?) {
                            false
                          }

          expect {
            updater.update_payment_state
          }.to change { order.payment_state }.to 'credit_owed'
        end
      end

      context "and payment is refunded" do
        it "is void" do
          order.payment_total = 0
          order.total = 30
          allow(order).to receive_message_chain(:payments, :valid, :empty?) { false }
          allow(order).to receive_message_chain(:payments, :completed, :empty?) { false }

          expect {
            updater.update_payment_state
          }.to change { order.payment_state }.to 'void'
        end
      end
    end

    context 'when the set payment_state matches the last payment_state' do
      before { order.payment_state = 'paid' }

      it 'does not create any state_change' do
        expect { updater.update_payment_state }
          .not_to change { order.state_changes.size }
      end
    end

    context 'when the set payment_state does not match the last payment_state' do
      before { order.payment_state = 'previous_to_paid' }

      context 'and the order is being updated' do
        before { allow(order).to receive(:persisted?) { true } }

        it 'creates a new state_change for the order' do
          expect { updater.update_payment_state }
            .to change { order.state_changes.size }.by(1)
        end
      end

      context 'and the order is being created' do
        before { allow(order).to receive(:persisted?) { false } }

        it 'creates a new state_change for the order' do
          expect { updater.update_payment_state }
            .not_to change { order.state_changes.size }
        end
      end
    end

    context "when unused payments records exist which require authorization, " \
            "but the order is fully paid" do
      let!(:cash_payment) {
        build(:payment, state: "completed", amount: order.new_outstanding_balance)
      }
      let!(:stripe_payment) { build(:payment, state: "requires_authorization") }
      before do
        order.payments << cash_payment
        order.payments << stripe_payment
      end

      it "cancels unused payments requiring authorization" do
        expect(stripe_payment).to receive(:void_transaction!)
        expect(cash_payment).not_to receive(:void_transaction!)

        order.updater.update_payment_state
      end
    end
  end

  describe '#shipping_address_from_distributor' do
    let(:distributor) { build(:distributor_enterprise) }
    let(:shipment) {
      create(:shipment_with, :shipping_method, shipping_method:)
    }

    before do
      order.distributor = distributor
      order.shipments = [shipment]
    end

    context 'when shipping method is pickup' do
      let(:shipping_method) { create(:shipping_method_with, :pickup) }
      let(:address) { build(:address, firstname: 'joe') }
      before { distributor.address = address }

      it "populates the shipping address from distributor" do
        updater.shipping_address_from_distributor
        expect(order.ship_address.address1).to eq(distributor.address.address1)
      end
    end

    context 'when shipping_method is delivery' do
      let(:shipping_method) { create(:shipping_method_with, :delivery) }
      let(:address) { build(:address, firstname: 'will') }
      before { order.ship_address = address }

      it "does not populate the shipping address from distributor" do
        updater.shipping_address_from_distributor
        expect(order.ship_address.firstname).to eq("will")
      end
    end
  end

  describe "#update_totals_and_states" do
    it "deals with legacy taxes" do
      expect(updater).to receive(:handle_legacy_taxes)

      updater.update_totals_and_states
    end
  end

  describe "#handle_legacy_taxes" do
    context "when the order is incomplete" do
      it "doesn't touch taxes" do
        allow(order).to receive(:completed?) { false }

        expect(order).not_to receive(:create_tax_charge!)
        updater.__send__(:handle_legacy_taxes)
      end
    end

    context "when the order is complete" do
      before { allow(order).to receive(:completed?) { true } }

      context "and the order has legacy taxes" do
        let!(:legacy_tax_adjustment) {
          create(:adjustment, order:, adjustable: order, included: false,
                              originator_type: "Spree::TaxRate")
        }

        it "re-applies order taxes" do
          expect(order).to receive(:create_tax_charge!)

          updater.__send__(:handle_legacy_taxes)
        end
      end

      context "and the order has no legacy taxes" do
        it "leaves taxes untouched" do
          expect(order).not_to receive(:create_tax_charge!)

          updater.__send__(:handle_legacy_taxes)
        end
      end
    end
  end

  describe "#update_voucher" do
    let(:voucher_service) { instance_double(VoucherAdjustmentsService) }

    it "calls VoucherAdjustmentsService" do
      expect(VoucherAdjustmentsService).to receive(:new).and_return(voucher_service)
      expect(voucher_service).to receive(:update)

      updater.update_voucher
    end

    it "calls update_totals_and_states" do
      allow(VoucherAdjustmentsService).to receive(:new).and_return(voucher_service)
      allow(voucher_service).to receive(:update)

      expect(updater).to receive(:update_totals_and_states)

      updater.update_voucher
    end
  end

  def update_order_quantity(order)
    order.line_items.first.update_attribute(:quantity, 2)
  end
end
