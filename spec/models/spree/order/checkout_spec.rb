require 'spec_helper'

describe Spree::Order do
  let(:order) { Spree::Order.new }

  context "with default state machine" do
    let(:transitions) do
      [
        { address: :delivery },
        { delivery: :payment },
        { payment: :complete },
        { delivery: :complete }
      ]
    end

    it "has the following transitions" do
      transitions.each do |transition|
        puts transition.keys.first
        puts transition.values.first
        transition = Spree::Order.find_transition(from: transition.keys.first,
                                                  to: transition.values.first)
        expect(transition).to_not be_nil
      end
    end

    it "does not have a transition from delivery to confirm" do
      transition = Spree::Order.find_transition(from: :delivery, to: :confirm)
      expect(transition).to be_nil
    end

    it '.find_transition when contract was broken' do
      expect(Spree::Order.find_transition({ foo: :bar, baz: :dog })).to be_falsy
    end

    it '.remove_transition' do
      options = { from: transitions.first.keys.first, to: transitions.first.values.first }
      allow(Spree::Order).to receive(:next_event_transition).and_return([options])
      expect(Spree::Order.remove_transition(options)).to be_truthy
    end

    it '.remove_transition when contract was broken' do
      expect(Spree::Order.remove_transition(nil)).to be_falsy
    end

    context "#checkout_steps" do
      context "when payment not required" do
        before { allow(order).to receive_messages payment_required?: false }
        specify do
          expect(order.checkout_steps).to eq %w(address delivery complete)
        end
      end

      context "when payment required" do
        before { allow(order).to receive_messages payment_required?: true }
        specify do
          expect(order.checkout_steps).to eq %w(address delivery payment complete)
        end
      end
    end

    it "starts out at cart" do
      expect(order.state).to eq "cart"
    end

    it "transitions to address" do
      order.line_items << FactoryBot.create(:line_item)
      order.email = "user@example.com"
      order.next!
      expect(order.state).to eq "address"
    end

    it "cannot transition to address without any line items" do
      expect(order.line_items).to be_blank
      expect(lambda { order.next! }).to raise_error(StateMachine::InvalidTransition,
                                                /#{Spree.t(:there_are_no_items_for_this_order)}/)
    end

    context "from address" do
      before do
        order.state = 'address'
        allow(order).to receive(:has_available_payment)
        order.shipments << create(:shipment)
        order.email = "user@example.com"
        order.save!
      end

      it "transitions to delivery" do
        allow(order).to receive_messages(ensure_available_shipping_rates: true)
        order.next!
        expect(order.state).to eq "delivery"
      end

      context "cannot transition to delivery" do
        context "if there are no shipping rates for any shipment" do
          specify do
            transition = lambda { order.next! }
            expect(transition).to raise_error(StateMachine::InvalidTransition,
                                          /#{Spree.t(:items_cannot_be_shipped)}/)
          end
        end
      end
    end

    context "from delivery" do
      before do
        order.state = 'delivery'
      end

      context "with payment required" do
        before do
          allow(order).to receive_messages payment_required?: true
        end

        it "transitions to payment" do
          order.next!
          expect(order.state).to eq 'payment'
        end
      end

      context "without payment required" do
        before do
          allow(order).to receive_messages payment_required?: false
        end

        it "transitions to complete" do
          order.next!
          expect(order.state).to eq "complete"
        end
      end
    end

    context "from payment" do
      before do
        order.state = 'payment'
      end

     context "when payment is required" do
        before do
          allow(order).to receive_messages confirmation_required?: false
          allow(order).to receive_messages payment_required?: true
        end

        it "transitions to complete" do
          expect(order).to receive(:process_payments!).once.and_return true
          order.next!
          expect(order.state).to eq "complete"
        end
      end

      # Regression test for Spree #2028
      context "when payment is not required" do
        before do
          allow(order).to receive_messages payment_required?: false
        end

        it "does not call process payments" do
          expect(order).to_not receive(:process_payments!)
          order.next!
          expect(order.state).to eq "complete"
        end
      end
    end
  end

  context "subclassed order" do
    # This causes another test above to fail, but fixing this test should make
    #   the other test pass
    class SubclassedOrder < Spree::Order
      checkout_flow do
        go_to_state :payment
        go_to_state :complete
      end
    end

    it "should only call default transitions once when checkout_flow is redefined" do
      order = SubclassedOrder.new
      allow(order).to receive_messages payment_required?: true
      expect(order).to receive(:process_payments!).once
      order.state = "payment"
      order.next!
      expect(order.state).to eq "complete"
    end
  end

  context "re-define checkout flow" do
    before do
      @old_checkout_flow = Spree::Order.checkout_flow
      Spree::Order.class_eval do
        checkout_flow do
          go_to_state :payment
          go_to_state :complete
        end
      end
    end

    after do
      Spree::Order.checkout_flow(&@old_checkout_flow)
    end

    it "should not keep old event transitions when checkout_flow is redefined" do
      expect(Spree::Order.next_event_transitions).to eq [{ cart: :payment }, { payment: :complete }]
    end

    it "should not keep old events when checkout_flow is redefined" do
      state_machine = Spree::Order.state_machine
      expect(state_machine.states.any? { |s| s.name == :address }).to be_falsy
      known_states = state_machine.events[:next].branches.map(&:known_states).flatten
      expect(known_states).to_not include(:address)
      expect(known_states).to_not include(:delivery)
      expect(known_states).to_not include(:confirm)
    end
  end

  # Regression test for Spree #3665
  context "with only a complete step" do
    before do
      @old_checkout_flow = Spree::Order.checkout_flow
      Spree::Order.class_eval do
        checkout_flow do
          go_to_state :complete
        end
      end
    end

    after do
      Spree::Order.checkout_flow(&@old_checkout_flow)
    end

    it "does not attempt to process payments" do
      allow(order).to receive_message_chain(:line_items, :present?).and_return(true)
      expect(order).to_not receive(:payment_required?)
      expect(order).to_not receive(:process_payments!)
      order.next!
    end
  end

  context "insert checkout step" do
    before do
      @old_checkout_flow = Spree::Order.checkout_flow
      Spree::Order.class_eval do
        insert_checkout_step :new_step, before: :address
      end
    end

    after do
      Spree::Order.checkout_flow(&@old_checkout_flow)
    end

    it "should maintain removed transitions" do
      transition = Spree::Order.find_transition(from: :delivery, to: :confirm)
      expect(transition).to be_nil
    end

    context "before" do
      before do
        Spree::Order.class_eval do
          insert_checkout_step :before_address, before: :address
        end
      end

      specify do
        order = Spree::Order.new
        expect(order.checkout_steps).to eq %w(new_step before_address address delivery complete)
      end
    end

    context "after" do
      before do
        Spree::Order.class_eval do
          insert_checkout_step :after_address, after: :address
        end
      end

      specify do
        order = Spree::Order.new
        expect(order.checkout_steps).to eq %w(new_step address after_address delivery complete)
      end
    end
  end

  context "remove checkout step" do
    before do
      @old_checkout_flow = Spree::Order.checkout_flow
      Spree::Order.class_eval do
        remove_checkout_step :address
      end
    end

    after do
      Spree::Order.checkout_flow(&@old_checkout_flow)
    end

    it "should maintain removed transitions" do
      transition = Spree::Order.find_transition(from: :delivery, to: :confirm)
      expect(transition).to be_nil
    end

    specify do
      order = Spree::Order.new
      expect(order.checkout_steps).to eq %w(delivery complete)
    end
  end

  describe 'event :restart_checkout' do
    let(:order) { create(:order) }

    context 'when the order is not complete' do
      before { allow(order).to receive(:completed?) { false } }

      it 'does transition to cart state' do
        expect(order.state).to eq('cart')
      end
    end

    context 'when the order is complete' do
      before { allow(order).to receive(:completed?) { true } }

      it 'raises' do
        expect { order.restart_checkout! }
          .to raise_error(
            StateMachine::InvalidTransition,
            /Cannot transition state via :restart_checkout/
          )
      end
    end
  end

  describe "order with products with different shipping categories" do
    let(:order) { create(:order_with_totals_and_distribution, ship_address: create(:address) ) }
    let(:shipping_method) { create(:shipping_method, distributors: [order.distributor]) }
    let(:other_shipping_category) { create(:shipping_category) }
    let(:other_product) { create(:product, shipping_category: other_shipping_category ) }
    let(:other_variant) { other_product.variants.first }

    before do
      order.order_cycle = create(:simple_order_cycle,
                                 distributors: [order.distributor],
                                 variants: [order.line_items.first.variant, other_variant])
      order.line_items << create(:line_item, order: order, variant: other_variant)
    end

    it "can progress to delivery" do
      shipping_method.shipping_categories << other_shipping_category

      order.next
      order.next
      expect(order.state).to eq "delivery"
    end
  end
end
