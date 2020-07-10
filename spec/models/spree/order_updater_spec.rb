require 'spec_helper'

module Spree
  describe OrderUpdater do
    let(:order) { build(:order) }
    let(:updater) { Spree::OrderUpdater.new(order) }

    before { allow(order).to receive(:backordered?) { false } }

    it "updates totals" do
      payments = [double(:amount => 5), double(:amount => 5)]
      allow(order).to receive_message_chain(:payments, :completed).and_return(payments)

      line_items = [double(:amount => 10), double(:amount => 20)]
      allow(order).to receive_messages :line_items => line_items

      adjustments = [double(:amount => 10), double(:amount => -20)]
      allow(order).to receive_message_chain(:adjustments, :eligible).and_return(adjustments)

      updater.update_totals
      expect(order.payment_total).to eq 10
      expect(order.item_total).to eq 30
      expect(order.adjustment_total).to eq -10
      expect(order.total).to eq 20
    end

    context "updating shipment state" do
      before do
        allow(order).to receive_message_chain(:shipments, :shipped, :count).and_return(0)
        allow(order).to receive_message_chain(:shipments, :ready, :count).and_return(0)
        allow(order).to receive_message_chain(:shipments, :pending, :count).and_return(0)
      end

      it "is backordered" do
        allow(order).to receive(:backordered?) { true }
        updater.update_shipment_state

        expect(order.shipment_state).to eq 'backorder'
      end

      it "is nil" do
        allow(order).to receive_message_chain(:shipments, :states).and_return([])
        allow(order).to receive_message_chain(:shipments, :count).and_return(0)

        updater.update_shipment_state
        expect(order.shipment_state).to be_nil
      end


      ["shipped", "ready", "pending"].each do |state|
        it "is #{state}" do
          allow(order).to receive_message_chain(:shipments, :states).and_return([state])
          updater.update_shipment_state
          expect(order.shipment_state).to eq state.to_s
        end
      end

      it "is partial" do
        allow(order).to receive_message_chain(:shipments, :states).and_return(["pending", "ready"])
        updater.update_shipment_state
        expect(order.shipment_state).to eq 'partial'
      end
    end

    context "updating payment state" do
      it "is failed if last payment failed" do
        allow(order).to receive_message_chain(:payments, :last, :state).and_return('failed')

        updater.update_payment_state
        expect(order.payment_state).to eq 'failed'
      end

      it "is balance due with no line items" do
        allow(order).to receive_message_chain(:line_items, :empty?).and_return(true)

        updater.update_payment_state
        expect(order.payment_state).to eq 'balance_due'
      end

      it "is credit owed if payment is above total" do
        allow(order).to receive_message_chain(:line_items, :empty?).and_return(false)
        allow(order).to receive_messages :payment_total => 31
        allow(order).to receive_messages :total => 30

        updater.update_payment_state
        expect(order.payment_state).to eq 'credit_owed'
      end

      it "is paid if order is paid in full" do
        allow(order).to receive_message_chain(:line_items, :empty?).and_return(false)
        allow(order).to receive_messages :payment_total => 30
        allow(order).to receive_messages :total => 30

        updater.update_payment_state
        expect(order.payment_state).to eq 'paid'
      end
    end

    it "state change" do
      order = create(:order)
      order.shipment_state = 'shipped'
      state_changes = double
      allow(order).to receive(:state_changes) { state_changes }
      expect(state_changes).to receive(:create).with(
        :previous_state => nil,
        :next_state => 'shipped',
        :name => 'shipment',
        :user_id => order.user_id
      )

      order.state_changed('shipment')
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

      it "updates each shipment" do
        shipment = build(:shipment)
        shipments = [shipment]
        allow(order).to receive_messages :shipments => shipments
        allow(shipments).to receive_messages :states => []
        allow(shipments).to receive_messages :ready => []
        allow(shipments).to receive_messages :pending => []
        allow(shipments).to receive_messages :shipped => []

        expect(shipment).to receive(:update!).with(order)
        updater.update
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

      it "doesnt update each shipment" do
        shipment = build(:shipment)
        shipments = [shipment]
        allow(order).to receive_messages :shipments => shipments
        allow(shipments).to receive_messages :states => []
        allow(shipments).to receive_messages :ready => []
        allow(shipments).to receive_messages :pending => []
        allow(shipments).to receive_messages :shipped => []

        expect(shipment).not_to receive(:update!).with(order)
        updater.update
      end
    end

    it "updates totals twice" do
      expect(updater).to receive(:update_totals).twice
      updater.update
    end

    context "update adjustments" do
      context "shipments" do
        it "updates" do
          expect(updater).to receive(:update_shipping_adjustments)
          updater.update
        end
      end

      context "promotions" do
        let(:originator) do
          originator = Spree::Promotion::Actions::CreateAdjustment.create
          calculator = Spree::Calculator::PerItem.create(:calculable => originator)
          originator.calculator = calculator
          originator.save
          originator
        end

        def create_adjustment(label, amount)
          create(:adjustment, :adjustable => order,
                              :originator => originator,
                              :amount     => amount,
                              :state      => "closed",
                              :label      => label,
                              :mandatory  => false)
        end

        it "should make all but the most valuable promotion adjustment ineligible, leaving non promotion adjustments alone" do
          create_adjustment("Promotion A", -100)
          create_adjustment("Promotion B", -200)
          create_adjustment("Promotion C", -300)
          create(:adjustment, :adjustable => order,
                              :originator => nil,
                              :amount => -500,
                              :state => "closed",
                              :label => "Some other credit")
          order.adjustments.each {|a| a.update_column(:eligible, true)}

          updater.update_promotion_adjustments

          expect(order.adjustments.eligible.promotion.count).to eq 1
          expect(order.adjustments.eligible.promotion.first.label).to eq 'Promotion C'
        end

        context "multiple adjustments and the best one is not eligible" do
          let!(:promo_a) { create_adjustment("Promotion A", -100) }
          let!(:promo_c) { create_adjustment("Promotion C", -300) }

          before do
            promo_a.update_column(:eligible, true)
            promo_c.update_column(:eligible, false)
          end

          # regression for #3274
          it "still makes the previous best eligible adjustment valid" do
            updater.update_promotion_adjustments
            expect(order.adjustments.eligible.promotion.first.label).to eq 'Promotion A'
          end
        end

        it "should only leave one adjustment even if 2 have the same amount" do
          create_adjustment("Promotion A", -100)
          create_adjustment("Promotion B", -200)
          create_adjustment("Promotion C", -200)

          updater.update_promotion_adjustments

          expect(order.adjustments.eligible.promotion.count).to eq 1
          expect(order.adjustments.eligible.promotion.first.amount.to_i).to eq -200
        end

        it "should only include eligible adjustments in promo_total" do
          create_adjustment("Promotion A", -100)
          create(:adjustment, :adjustable => order,
                              :originator => nil,
                              :amount     => -1000,
                              :state      => "closed",
                              :eligible   => false,
                              :label      => 'Bad promo')

          expect(order.promo_total.to_f).to eq -100.to_f
        end
      end
    end
  end
end
