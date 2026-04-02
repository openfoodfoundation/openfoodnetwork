# frozen_string_literal: false

RSpec.describe Spree::Order do
  let(:user) { build(:user, email: "spree@example.com") }
  let(:order) { build(:order, user:) }

  it { is_expected.to have_one :exchange }
  it { is_expected.to have_many :semantic_links }

  describe "#errors" do
    it "provides friendly error messages" do
      order.ship_address = Spree::Address.new
      order.save
      expect(order.errors.full_messages)
        .to include "Shipping address (Street + House number) can't be blank"
    end

    it "provides friendly error messages for bill address" do
      order.bill_address = Spree::Address.new
      order.save
      expect(order.errors.full_messages)
        .to include "Billing address (Street + House number) can't be blank"
    end
  end

  context "#products" do
    let(:order) { create(:order_with_line_items) }

    it "should return ordered products" do
      expect(order.products.first).to eq order.line_items.first.product
    end

    it "contains?" do
      expect(order.contains?(order.line_items.first.variant)).to be_truthy
    end

    it "can find a line item matching a given variant" do
      expect(order.find_line_item_by_variant(order.line_items.third.variant)).not_to be_nil
      expect(order.find_line_item_by_variant(build(:variant))).to be_nil
    end
  end

  context "#generate_order_number" do
    it "should generate a random string" do
      expect(order.generate_order_number.is_a?(String)).to be_truthy
      order.number = nil
      expect(!order.generate_order_number.to_s.empty?).to be_truthy
    end
  end

  context "#associate_user!" do
    it "should associate a user with a persisted order" do
      order = create(:order_with_line_items, created_by: nil)
      user = create(:user)

      order.user = nil
      order.email = nil
      order.associate_user!(user)
      expect(order.user).to eq user
      expect(order.email).to eq user.email
      expect(order.created_by).to eq user

      # verify that the changes we made were persisted
      order.reload
      expect(order.user).to eq user
      expect(order.email).to eq user.email
      expect(order.created_by).to eq user
    end

    it "should not overwrite the created_by if it already is set" do
      creator = create(:user)
      order = create(:order_with_line_items, created_by: creator)
      user = create(:user)

      order.user = nil
      order.email = nil
      order.associate_user!(user)
      expect(order.user).to eq user
      expect(order.email).to eq user.email
      expect(order.created_by).to eq creator

      # verify that the changes we made were persisted
      order.reload
      expect(order.user).to eq user
      expect(order.email).to eq user.email
      expect(order.created_by).to eq creator
    end

    it "should associate a user with a non-persisted order" do
      order = Spree::Order.new

      expect do
        order.associate_user!(user)
      end.to change { [order.user, order.email] }.from([nil, nil]).to([user, user.email])
    end

    it "should not persist an invalid address" do
      address = Spree::Address.new
      order.user = nil
      order.email = nil
      order.ship_address = address
      expect do
        order.associate_user!(user)
      end.not_to change { address.persisted? }.from(false)
    end
  end

  context "#create" do
    it "should assign an order number" do
      order = Spree::Order.create
      expect(order.number).not_to be_nil
    end
  end

  context "#can_ship?" do
    let(:order) { Spree::Order.create }

    it "should be true for order in the 'complete' state" do
      allow(order).to receive_messages(complete?: true)
      expect(order.can_ship?).to be_truthy
    end

    it "should be true for order in the 'resumed' state" do
      allow(order).to receive_messages(resumed?: true)
      expect(order.can_ship?).to be_truthy
    end

    it "should be true for an order in the 'awaiting return' state" do
      allow(order).to receive_messages(awaiting_return?: true)
      expect(order.can_ship?).to be_truthy
    end

    it "should be true for an order in the 'returned' state" do
      allow(order).to receive_messages(returned?: true)
      expect(order.can_ship?).to be_truthy
    end

    it "should be false if the order is neither in the 'complete' nor 'resumed' state" do
      allow(order).to receive_messages(resumed?: false, complete?: false)
      expect(order.can_ship?).to be_falsy
    end
  end

  context '#changes_allowed?' do
    let(:order) { create(:order_ready_for_details) }
    let(:complete) { true }
    let(:shipped) { false }
    let(:distributor_allow_changes) { true }
    let(:order_cycle_open) { true }

    subject { order.changes_allowed? }

    before do
      allow(order).to receive(:complete?).and_return(complete)
      allow(order).to receive(:shipped?).and_return(shipped)
      allow_any_instance_of(Enterprise).to receive(:allow_order_changes?).and_return(
        distributor_allow_changes
      )
      allow_any_instance_of(OrderCycle).to receive(:open?).and_return(order_cycle_open)
    end

    context 'valid conditions' do
      let(:complete) { true }
      let(:shipped) { false }
      let(:distributor_allow_changes) { true }
      let(:order_cycle_open) { true }

      it { is_expected.to eq(true) }
    end

    context 'already shipped' do
      let(:shipped) { true }

      it { is_expected.to eq(false) }
    end

    context 'not complete' do
      let(:complete) { false }

      it { is_expected.to eq(false) }
    end

    context 'distributor changes not allowed' do
      let(:distributor_allow_changes) { false }

      it { is_expected.to eq(false) }
    end

    context 'order does not have distributor' do
      let(:order) { build(:order, distributor: nil, order_cycle: build(:order_cycle)) }

      it { is_expected.to eq(false) }
    end

    context 'order cycle not open' do
      let(:order_cycle_open) { false }

      it { is_expected.to eq(false) }
    end

    context 'order does not have order cycle' do
      let(:order) { build(:order, distributor: build(:distributor_enterprise), order_cycle: nil) }

      it { is_expected.to eq(false) }
    end
  end

  context "checking if order is paid" do
    context "payment_state is paid" do
      before { allow(order).to receive_messages payment_state: 'paid' }
      it { expect(order).to be_paid }
    end

    context "payment_state is credit_owned" do
      before { allow(order).to receive_messages payment_state: 'credit_owed' }
      it { expect(order).to be_paid }
    end
  end

  describe "#finalize!" do
    subject(:order) { Spree::Order.create }

    it "should set completed_at" do
      expect {
        order.finalize!
        order.reload
      }.to change {
        order.completed_at
      }.from(nil)
    end

    it "updates shipments and decreases stock" do
      order = create(:order_ready_for_confirmation)
      shipment = order.shipments.first
      shipment.update_columns(updated_at: 1.minute.ago)

      expect {
        order.finalize!
      }.to change { order.variants.first.on_hand }.by(-1)
        .and change { shipment.updated_at }
    end

    it "should change the shipment state to ready if order is paid" do
      order = create(:order_ready_for_confirmation)

      order.payments.first.capture!
      order.next! # calls `finalize!`
      order.reload # reload so we're sure the changes are persisted

      expect(order.shipment_state).to eq 'ready'
    end

    it "sends confirmation emails to both the user and the shop owner" do
      mailer = double(:mailer, deliver_later: true)

      expect(Spree::OrderMailer).to receive(:confirm_email_for_customer).and_return(mailer)
      expect(Spree::OrderMailer).to receive(:confirm_email_for_shop).and_return(mailer)

      order.finalize!
    end

    it "should freeze all adjustments" do
      adjustments = double
      allow(order).to receive_messages all_adjustments: adjustments
      expect(adjustments).to receive(:update_all).with(state: 'closed')
      order.finalize!
    end

    it "should log state event" do
      # order, shipment & payment state changes
      expect(order.state_changes).to receive(:create).exactly(3).times
      order.finalize!
    end

    it 'calls updater#shipping_address_from_distributor' do
      expect(order.updater).to receive(:shipping_address_from_distributor)
      order.finalize!
    end
  end

  describe "#process_payments!" do
    let(:payment) { build(:payment) }
    before { allow(order).to receive_messages pending_payments: [payment], total: 10 }

    context "when the processing is sucessful" do
      it "processes the payments" do
        expect(payment).to receive(:process!)
        expect(order.process_payments!).to be_truthy
      end
    end

    context "when a payment raises a GatewayError" do
      before { expect(payment).to receive(:process!).and_raise(Spree::Core::GatewayError) }

      it "returns false" do
        expect(order.process_payments!).to be_falsy
      end
    end
  end

  context "#completed?" do
    it "should indicate if order is completed" do
      order.completed_at = nil
      expect(order.completed?).to be_falsy

      order.completed_at = Time.zone.now
      expect(order.completed?).to be_truthy
    end
  end

  context "#allow_checkout?" do
    it "should be true if there are line_items in the order" do
      allow(order).to receive_message_chain(:line_items, count: 1)
      expect(order.checkout_allowed?).to be_truthy
    end
    it "should be false if there are no line_items in the order" do
      allow(order).to receive_message_chain(:line_items, count: 0)
      expect(order.checkout_allowed?).to be_falsy
    end
  end

  context "#amount" do
    before do
      @order = create(:order, user:)
      @order.line_items = [create(:line_item, price: 1.0, quantity: 2),
                           create(:line_item, price: 1.0, quantity: 1)]
    end
    it "should return the correct lum sum of items" do
      expect(@order.amount).to eq 3.0
    end
  end

  context "#can_cancel?" do
    it "should be false for completed order in the canceled state" do
      order.state = 'canceled'
      order.shipment_state = 'ready'
      order.completed_at = Time.zone.now
      expect(order.can_cancel?).to be_falsy
    end

    it "should be true for completed order with no shipment" do
      order.state = 'complete'
      order.shipment_state = nil
      order.completed_at = Time.zone.now
      expect(order.can_cancel?).to be_truthy
    end

    context "with a soft-deleted product" do
      let(:order) { create(:completed_order_with_totals) }

      it "should cancel the order without error" do
        order.line_items.first.variant.product.tap(&:destroy)
        order.cancel!
        expect(Spree::Order.by_state(:canceled)).to include order
      end
    end
  end

  describe "#cancel!" do
    let(:order) { create(:order_with_totals_and_distribution, :completed) }

    it "should cancel the order" do
      expect { order.cancel! }.to change { order.state }.to("canceled")
    end

    it "should cancel the shipments" do
      expect { order.cancel! }.to change {
        order.shipments.pluck(:state)
      }.to(["canceled"])
    end

    context "when payment has not been taken" do
      context "and payment is in checkout state" do
        it "should change the state of the payment to void" do
          expect {
            order.cancel!
            order.payments.reload
          }.to change {
            order.payments.pluck(:state)
          }.to(["void"])
        end
      end
    end

    it "restocks items without reload" do
      pending "Cancelling a newly created order updates shipments without callbacks"
      # But in production, orders are always created in one request and
      # cancelled in another request. This is only an issue in specs.

      expect { order.cancel }.to change {
        order.variants.first.on_hand
      }.by(1)
    end

    it "restocks items" do
      # If we don't reload the order, it keeps thinking that its shipping
      # address changed and triggers a shipment update without shipment
      # callbacks. This can be removed if the above spec passes.
      order.reload

      expect { order.cancel }.to change {
        order.variants.first.on_hand
      }.by(1)
    end
  end

  describe "#resume" do
    let(:order) { create(:order_with_totals_and_distribution, :completed) }

    before do
      order.cancel!
      order.reload
      order.resume!
    end

    it "should resume the order" do
      expect(order.state).to eq 'resumed'
    end

    it "should resume the shipments" do
      expect(order.shipments.pluck(:state)).to eq ['pending']
    end

    context "when payment is in void state" do
      it "should change the state of the payment to checkout" do
        order.payments.reload
        expect(order.payments.pluck(:state)).to eq ['checkout']
      end
    end
  end

  context "insufficient_stock_lines" do
    let(:line_item) { build(:line_item) }

    before do
      allow(order).to receive_messages(line_items: [line_item])
      allow(line_item).to receive(:insufficient_stock?) { true }
    end

    it "should return line_item that has insufficient stock on hand" do
      expect(order.insufficient_stock_lines.size).to eq 1
      expect(order.insufficient_stock_lines.include?(line_item)).to be_truthy
    end
  end

  context "empty!" do
    it "should clear out all line items and adjustments" do
      order = build(:order)
      expect(order.line_items).to receive(:destroy_all)
      expect(order.all_adjustments).to receive(:destroy_all)

      order.empty!
    end
  end

  context "#display_outstanding_balance" do
    it "returns the value as a spree money" do
      allow(order).to receive(:new_outstanding_balance) { 10.55 }
      expect(order.display_outstanding_balance).to eq Spree::Money.new(10.55)
    end
  end

  context "#display_item_total" do
    it "returns the value as a spree money" do
      allow(order).to receive(:item_total) { 10.55 }
      expect(order.display_item_total).to eq Spree::Money.new(10.55)
    end
  end

  context "#display_adjustment_total" do
    it "returns the value as a spree money" do
      order.adjustment_total = 10.55
      expect(order.display_adjustment_total).to eq Spree::Money.new(10.55)
    end
  end

  context "#display_total" do
    it "returns the value as a spree money" do
      order.total = 10.55
      expect(order.display_total).to eq Spree::Money.new(10.55)
    end
  end

  context "#currency" do
    context "when object currency is ABC" do
      before { order.currency = "ABC" }

      it "returns the currency from the object" do
        expect(order.currency).to eq "ABC"
      end
    end

    context "when object currency is nil" do
      before { order.currency = nil }

      it "returns the globally configured currency" do
        expect(order.currency).to eq "AUD"
      end
    end
  end

  # Regression test for Spree #2191
  context "when an order has an adjustment that zeroes the total, but another adjustment " \
          "for shipping that raises it above zero" do
    let!(:persisted_order) { create(:order) }
    let!(:line_item) { create(:line_item) }
    let!(:shipping_method) do
      sm = create(:shipping_method)
      sm.calculator.preferred_amount = 10
      sm.save
      sm
    end

    before do
      persisted_order.line_items << line_item
      persisted_order.adjustments.create(amount: -line_item.amount, label: "Promotion")
      persisted_order.state = 'delivery'
      persisted_order.save # To ensure new state_change event
    end

    it "transitions from delivery to payment" do
      allow(persisted_order).to receive_messages(payment_required?: true)
      persisted_order.next!
      expect(persisted_order.state).to eq "payment"
    end
  end

  context "payment required?" do
    let(:order) { Spree::Order.new }

    context "total is zero" do
      it { expect(order.payment_required?).to be_falsy }
    end

    context "total > zero" do
      before { allow(order).to receive_messages(total: 1) }
      it { expect(order.payment_required?).to be_truthy }
    end
  end

  describe ".tax_address" do
    before { Spree::Config[:tax_using_ship_address] = tax_using_ship_address }
    subject { order.tax_address }

    context "when tax_using_ship_address is true" do
      let(:tax_using_ship_address) { true }

      it 'returns ship_address' do
        expect(subject).to eq order.ship_address
      end
    end

    context "when tax_using_ship_address is not true" do
      let(:tax_using_ship_address) { false }

      it "returns bill_address" do
        expect(subject).to eq order.bill_address
      end
    end
  end

  context '#updater' do
    it 'returns an OrderManagement::Order::Updater' do
      expect(order.updater.class).to eq OrderManagement::Order::Updater
    end
  end

  describe "email validation" do
    let(:order) { build(:order) }

    it "has errors if email is blank" do
      allow(order).to receive_messages(require_email: true)
      order.email = ""

      order.valid?
      expect(order.errors[:email]).to eq ["can't be blank", "is invalid"]
    end

    it "has errors if email is invalid" do
      allow(order).to receive_messages(require_email: true)
      order.email = "invalid_email"

      order.valid?
      expect(order.errors[:email]).to eq ["is invalid"]
    end

    it "has errors if email has invalid domain" do
      allow(order).to receive_messages(require_email: true)
      order.email = "single_letter_tld@domain.z"

      order.valid?
      expect(order.errors[:email]).to eq ["is invalid"]
    end

    it "is valid if email is valid" do
      allow(order).to receive_messages(require_email: true)
      order.email = "a@b.ca"

      order.valid?
      expect(order.errors[:email]).to eq []
    end
  end

  describe "getting the admin and handling charge" do
    let(:o) { create(:order) }
    let(:li) { create(:line_item, order: o) }

    it "returns the sum of eligible enterprise fee adjustments" do
      ef = create(:enterprise_fee, calculator: Calculator::FlatRate.new )
      ef.calculator.set_preference :amount, 123.45
      a = ef.create_adjustment("adjustment", o, true)

      expect(o.admin_and_handling_total).to eq(123.45)
    end

    it "does not include ineligible adjustments" do
      ef = create(:enterprise_fee, calculator: Calculator::FlatRate.new )
      ef.calculator.set_preference :amount, 123.45
      a = ef.create_adjustment("adjustment", o, true)

      a.update_column :eligible, false

      expect(o.admin_and_handling_total).to eq(0)
    end

    it "does not include adjustments that do not originate from enterprise fees" do
      sm = create(:shipping_method, calculator: Calculator::FlatRate.new )
      sm.calculator.set_preference :amount, 123.45
      sm.create_adjustment("adjustment", o, true)

      expect(o.admin_and_handling_total).to eq(0)
    end

    it "does not include adjustments whose source is a line item" do
      ef = create(:enterprise_fee, calculator: Calculator::PerItem.new )
      ef.calculator.set_preference :amount, 123.45
      ef.create_adjustment("adjustment", li, true)

      expect(o.admin_and_handling_total).to eq(0)
    end
  end

  describe "an order without shipping method" do
    let(:order) { create(:order) }

    it "cannot be shipped" do
      expect(order.ready_to_ship?).to eq(false)
    end
  end

  describe "an unpaid order with a shipment" do
    let(:order) { create(:order_with_totals, shipments: [create(:shipment)]) }

    before do
      order.reload
      order.state = 'complete'
      order.shipment.update!(order)
    end

    it "cannot be shipped" do
      expect(order.ready_to_ship?).to eq(false)
    end
  end

  describe "a paid order without a shipment" do
    let(:order) { create(:order) }

    before do
      order.payment_state = 'paid'
      order.state = 'complete'
    end

    it "cannot be shipped" do
      expect(order.ready_to_ship?).to eq(false)
    end
  end

  describe "a paid order with a shipment" do
    let(:order) { create(:order_with_line_items) }

    before do
      order.payment_state = 'paid'
      order.state = 'complete'
      order.shipment.update!(order)
    end

    it "can be shipped" do
      expect(order.ready_to_ship?).to eq(true)
    end
  end

  describe "getting the shipping tax" do
    let(:order) { create(:order) }
    let(:shipping_tax_rate) {
      create(:tax_rate, amount: 0.25, included_in_price: true, zone: create(:zone_with_member))
    }
    let(:shipping_tax_category) { create(:tax_category, tax_rates: [shipping_tax_rate]) }
    let!(:shipping_method) {
      create(:shipping_method_with, :flat_rate, tax_category: shipping_tax_category)
    }

    context "with a taxed shipment" do
      let!(:shipment) {
        create(:shipment_with, :shipping_method, shipping_method:, order:)
      }

      before do
        allow(order).to receive(:tax_zone) { shipping_tax_rate.zone }
        order.update_attribute(:state, 'payment')
        order.reload
        order.create_tax_charge!
      end

      it "returns the shipping tax" do
        expect(order.shipping_tax).to eq(10)
      end
    end

    context 'when the order has not been shipped' do
      it "returns zero when the order has not been shipped" do
        expect(order.shipping_tax).to eq(0)
      end
    end
  end

  describe "#enterprise_fee_tax" do
    let!(:order) { create(:order) }
    let(:enterprise_fee) { create(:enterprise_fee) }
    let!(:fee_adjustment) {
      create(:adjustment, adjustable: order, originator: enterprise_fee,
                          amount: 100, order:, state: "closed")
    }
    let!(:fee_tax1) {
      create(:adjustment, adjustable: fee_adjustment, originator_type: "Spree::TaxRate",
                          amount: 12.3, order:, state: "closed")
    }
    let!(:fee_tax2) {
      create(:adjustment, adjustable: fee_adjustment, originator_type: "Spree::TaxRate",
                          amount: 4.5, order:, state: "closed")
    }
    let!(:admin_adjustment) {
      create(:adjustment, adjustable: order, originator: nil,
                          amount: 6.7, order:, state: "closed")
    }

    it "returns a sum of all taxes on enterprise fees" do
      expect(order.reload.enterprise_fee_tax).to eq(16.8)
    end
  end

  describe "getting the total tax" do
    let(:shipping_tax_rate) { create(:tax_rate, amount: 0.25) }
    let(:fee_tax_rate) { create(:tax_rate, amount: 0.10) }
    let(:order) { create(:order) }
    let(:shipping_method) { create(:shipping_method_with, :flat_rate) }
    let!(:shipment) do
      create(:shipment_with, :shipping_method, shipping_method:, order:)
    end
    let(:enterprise_fee) { create(:enterprise_fee) }
    let!(:fee) {
      create(:adjustment, adjustable: order, originator: enterprise_fee, label: "EF", amount: 20,
                          order:)
    }
    let!(:fee_tax) {
      create(:adjustment, adjustable: fee, originator: fee_tax_rate,
                          amount: 2, order:, state: "closed")
    }
    let!(:shipping_tax) {
      create(:adjustment, adjustable: shipment, originator: shipping_tax_rate,
                          amount: 10, order:, state: "closed")
    }

    before do
      order.update_order!
    end

    it "returns a sum of all tax on the order" do
      # 12 = 2 (of the enterprise fee adjustment) + 10 (of the shipment adjustment)
      expect(order.total_tax).to eq(12)
    end
  end

  describe "setting the distributor" do
    it "sets the distributor when no order cycle is set" do
      d = create(:distributor_enterprise)
      subject.assign_distributor! d
      expect(subject.distributor).to eq(d)
    end

    it "keeps the order cycle when it is available at the new distributor" do
      d = create(:distributor_enterprise)
      oc = create(:simple_order_cycle)
      create(:exchange, order_cycle: oc, sender: oc.coordinator, receiver: d, incoming: false)

      subject.order_cycle = oc
      subject.assign_distributor! d

      expect(subject.distributor).to eq(d)
      expect(subject.order_cycle).to eq(oc)
    end

    it "clears the order cycle if it is not available at that distributor" do
      d = create(:distributor_enterprise)
      oc = create(:simple_order_cycle)

      subject.order_cycle = oc
      subject.assign_distributor! d

      expect(subject.distributor).to eq(d)
      expect(subject.order_cycle).to be_nil
    end

    it "clears the distributor when setting to nil" do
      d = create(:distributor_enterprise)
      subject.assign_distributor! d
      subject.assign_distributor! nil

      expect(subject.distributor).to be_nil
    end
  end

  describe "emptying the order" do
    it "removes shipments" do
      subject.shipments << create(:shipment)
      subject.save!
      subject.empty!
      expect(subject.shipments).to be_empty
    end

    it "removes payments" do
      subject.payments << create(:payment)
      subject.save!
      subject.empty!
      expect(subject.payments).to be_empty
    end
  end

  describe "setting the order cycle" do
    let(:oc) { create(:simple_order_cycle) }

    it "empties the cart when changing the order cycle" do
      expect(subject).to receive(:empty!)
      subject.assign_order_cycle! oc
    end

    it "doesn't empty the cart if the order cycle is not different" do
      expect(subject).not_to receive(:empty!)
      subject.assign_order_cycle! subject.order_cycle
    end

    it "sets the order cycle when no distributor is set" do
      subject.assign_order_cycle! oc
      expect(subject.order_cycle).to eq(oc)
    end

    it "keeps the distributor when it is available in the new order cycle" do
      d = create(:distributor_enterprise)
      create(:exchange, order_cycle: oc, sender: oc.coordinator, receiver: d, incoming: false)

      subject.distributor = d
      subject.assign_order_cycle! oc

      expect(subject.order_cycle).to eq(oc)
      expect(subject.distributor).to eq(d)
    end

    it "clears the distributor if it is not available at that order cycle" do
      d = create(:distributor_enterprise)

      subject.distributor = d
      subject.assign_order_cycle! oc

      expect(subject.order_cycle).to eq(oc)
      expect(subject.distributor).to be_nil
    end

    it "clears the order cycle when setting to nil" do
      d = create(:distributor_enterprise)
      subject.assign_order_cycle! oc
      subject.distributor = d

      subject.assign_order_cycle! nil

      expect(subject.order_cycle).to be_nil
      expect(subject.distributor).to eq(d)
    end
  end

  context "change distributor and order cycle" do
    let(:variant1) { create(:product).variants.first }
    let(:variant2) { create(:product).variants.first }
    let(:distributor) { create(:enterprise) }

    before do
      subject.order_cycle = create(:simple_order_cycle, distributors: [distributor],
                                                        variants: [variant1, variant2])
      subject.distributor = distributor

      line_item1 = create(:line_item, order: subject, variant: variant1)
      line_item2 = create(:line_item, order: subject, variant: variant2)
      subject.reload
      subject.line_items = [line_item1, line_item2]
    end

    it "allows the change when all variants in the order are provided " \
       "by the new distributor in the new order cycle" do
      new_distributor = create(:enterprise)
      new_order_cycle = create(:simple_order_cycle, distributors: [new_distributor],
                                                    variants: [variant1, variant2])

      subject.distributor = new_distributor
      expect(subject).not_to be_valid
      subject.order_cycle = new_order_cycle
      expect(subject).to be_valid
    end

    it "doesn't allow change when not all variants in order are provided by new distributor" do
      new_distributor = create(:enterprise)
      create(:simple_order_cycle, distributors: [new_distributor], variants: [variant1])

      subject.distributor = new_distributor
      expect(subject).not_to be_valid
      expect(subject.errors.messages)
        .to eq(base: ["Distributor or order cycle cannot supply the products in your cart"])
    end
  end

  describe "scopes" do
    describe "invoiceable" do
      it "finds only active orders" do
        order_complete = create(:order, state: :complete)
        order_canceled = create(:order, state: :canceled)
        order_resumed = create(:order, state: :resumed)

        expect(Spree::Order.invoiceable).to match_array [
          order_complete,
          order_resumed,
        ]
      end
    end

    describe "not_state" do
      it "finds only orders not in specified state" do
        o = FactoryBot.create(:completed_order_with_totals,
                              distributor: create(:distributor_enterprise))
        o.cancel!
        expect(Spree::Order.not_state(:canceled)).not_to include o
      end
    end

    describe "not_empty" do
      let!(:order_with_line_items) { create(:order_with_line_items, line_items_count: 1) }
      let!(:order_without_line_items) { create(:order) }

      it "returns only orders which have line items" do
        expect(Spree::Order.not_empty).to include order_with_line_items
        expect(Spree::Order.not_empty).not_to include order_without_line_items
      end
    end
  end

  describe "sending confirmation emails" do
    let!(:distributor) { create(:distributor_enterprise) }
    let!(:order) { create(:order, distributor:) }

    it "sends confirmation emails" do
      mailer = double(:mailer, deliver_later: true)
      expect(Spree::OrderMailer).to receive(:confirm_email_for_customer).and_return(mailer)
      expect(Spree::OrderMailer).to receive(:confirm_email_for_shop).and_return(mailer)

      order.__send__(:deliver_order_confirmation_email)
    end

    it "does not send confirmation emails when the order belongs to a subscription" do
      create(:proxy_order, order:)

      expect(Spree::OrderMailer).not_to receive(:confirm_email_for_customer)
      expect(Spree::OrderMailer).not_to receive(:confirm_email_for_shop)

      order.__send__(:deliver_order_confirmation_email)
    end
  end

  describe "#customer" do
    it "is not required for new records" do
      is_expected.not_to validate_presence_of(:customer)
    end

    it "is not required for new complete orders" do
      order = Spree::Order.new(state: "complete")

      expect(order).not_to validate_presence_of(:customer)
    end

    it "is not required for existing orders in cart state" do
      order = create(:order)

      expect(order).not_to validate_presence_of(:customer)
    end

    it "is created for existing orders in complete state" do
      order = create(:order, state: "complete")

      expect { order.valid? }.to change { order.customer }.from(nil)
    end
  end

  describe "associating a customer" do
    let(:distributor) { create(:distributor_enterprise) }

    context "when creating an order" do
      it "does not create a customer" do
        expect {
          create(:order, distributor:)
        }.not_to change {
          Customer.count
        }
      end

      it "associates an existing customer" do
        customer = create(
          :customer,
          user:,
          email: user.email,
          enterprise: distributor
        )
        order = create(:order, user:, distributor:)

        expect(order.customer).to eq customer
      end
    end

    context "when updating the order" do
      before do
        order.update!(distributor:)
      end

      it "associates an existing customer" do
        customer = create(
          :customer,
          user:,
          email: user.email,
          enterprise: distributor
        )

        order.update!(state: "complete")

        expect(order.customer).to eq customer
      end

      it "doesn't create a customer before needed" do
        expect(order.customer).to eq nil
      end

      it "creates a customer" do
        expect {
          order.update!(state: "complete")
        }.to change {
          Customer.count
        }.by(1)

        expect(order.customer).to be_present
      end

      it "recognises users with changed email address" do
        order.update!(state: "complete")

        # Change email instantly without confirmation via Devise:
        order.user.update_columns(email: "new@email.org")

        other_order = create(:order, user: order.user, distributor:)

        expect {
          other_order.update!(state: "complete")
        }.not_to change { Customer.count }

        expect(other_order.customer.email).to eq "new@email.org"
        expect(order.customer).to eq other_order.customer
        expect(order.reload.customer.email).to eq "new@email.org"
      end

      it "resolves conflicts with duplicate customer entries" do
        order.update!(state: "complete")

        # The user may check out as guest first:
        guest_order = create(:order, user: nil, email: "new@email.org", distributor:)
        guest_order.update!(state: "complete")

        # Afterwards the user changes their email in their profile.
        # Change email instantly without confirmation via Devise:
        order.user.update_columns(email: "new@email.org")

        other_order = nil

        # The two customer entries are merged and one is deleted:
        expect {
          other_order = create(:order, user: order.user, distributor:)
        }.to change { Customer.count }.by(-1)

        expect(other_order.customer.email).to eq "new@email.org"
        expect(order.customer).to eq other_order.customer
        expect(order.reload.customer.email).to eq "new@email.org"

        expect(order.customer.orders).to match_array [
          order, guest_order, other_order
        ]
      end
    end
  end

  describe "when a guest order is placed with a registered email" do
    let(:order) { create(:order_with_totals_and_distribution, user:) }
    let(:payment_method) { create(:payment_method, distributors: [order.distributor]) }
    let(:shipping_method) { create(:shipping_method, distributors: [order.distributor]) }
    let(:user) { create(:user, email: 'registered@email.com') }

    before do
      order.bill_address = create(:address)
      order.ship_address = create(:address)
      order.email = user.email
      order.user = nil
      order.state = 'cart'
    end

    it "returns a validation error" do
      expect{ order.next }.to change { order.errors.count }.from(0).to(1)
      expect(order.errors.messages[:email]).to eq ['This email address is already registered. ' \
                                                   'Please log in to continue, or go back and ' \
                                                   'use another email address.']
      expect(order.state).to eq 'cart'
    end
  end

  describe "#update_shipping_fees!" do
    let(:distributor) { create(:distributor_enterprise) }
    let(:order) {
      create(:completed_order_with_fees, distributor:, shipping_fee:, payment_fee: 0)
    }
    let(:shipping_fee) { 5 }

    it "does nothing if shipment is shipped" do
      # An order need to be paid before we can ship a shipment
      create(:payment, amount: order.total, order:, state: "completed")

      shipment = order.shipments.first
      shipment.ship

      expect(shipment).not_to receive(:save)

      order.update_shipping_fees!
    end

    it "saves the each shipment" do
      order.shipments << create(:shipment, order:)
      order.shipments.each do |shipment|
        expect(shipment).to receive(:save)
      end

      order.update_shipping_fees!
    end

    context "with shipment including a shipping fee" do
      it "updates shipping fee" do
        # Manually udate line item quantity, in a normal scenario we would use
        # order.contents method, which takes care of updating shipments
        order.line_items.first.update(quantity: 2)

        order.update_shipping_fees!

        expect(order.reload.adjustment_total).to eq(15) # 3 items * 5
      end
    end
  end

  describe "a completed order with transaction fees" do
    let(:distributor) { create(:distributor_enterprise_with_tax) }
    let(:order) {
      create(:completed_order_with_fees, distributor:, shipping_fee: 0, payment_fee:)
    }
    let(:payment_fee) { 5 }
    let(:item_num) { order.line_items.length }
    let(:expected_fees) { item_num * payment_fee }

    before do
      order.reload
      order.create_tax_charge!

      # Sanity check the fees
      expect(order.all_adjustments.length).to eq 2
      expect(item_num).to eq 2
      expect(order.adjustment_total).to eq expected_fees
    end

    context "removing line_items" do
      it "updates transaction fees" do
        order.line_items.first.update_attribute(:quantity, 0)
        order.save

        expect(order.adjustment_total).to eq expected_fees - payment_fee
      end
    end

    context "changing the payment method to one without fees" do
      let(:payment_method) {
        create(:payment_method, calculator: Calculator::FlatRate.new(preferred_amount: 0))
      }

      it "removes transaction fees" do
        # Change the payment method
        order.payments.first.update(payment_method_id: payment_method.id)
        order.save

        # Check if fees got updated
        order.reload

        expect(order.adjustment_total).to eq expected_fees - (item_num * payment_fee)
      end
    end
  end

  describe "retrieving previously ordered items" do
    let(:distributor) { create(:distributor_enterprise) }
    let(:order_cycle) { create(:simple_order_cycle) }
    let!(:order) { create(:order, distributor:, order_cycle:) }

    it "returns no items if nothing has been ordered" do
      expect(order.finalised_line_items).to eq []
    end

    context "when no order has been finalised in this order cycle" do
      let(:product) { create(:product) }

      before do
        order.contents.update_or_create(product.variants.first, { quantity: 1, max_quantity: 3 })
      end

      it "returns no items even though the cart contains items" do
        expect(order.finalised_line_items).to eq []
      end
    end

    context "when an order has been finalised in this order cycle" do
      let!(:prev_order) {
        create(:completed_order_with_totals, distributor:, order_cycle:,
                                             user: order.user)
      }
      let!(:prev_order2) {
        create(:completed_order_with_totals, distributor:, order_cycle:,
                                             user: order.user)
      }
      let(:product) { create(:product) }

      before do
        prev_order.contents.update_or_create(product.variants.first,
                                             { quantity: 1, max_quantity: 3 })
        prev_order2.reload # to get the right response from line_items
      end

      it "returns previous items" do
        expect(order.finalised_line_items.length).to eq 11
        expect(order.finalised_line_items)
          .to match_array(prev_order.line_items + prev_order2.line_items)
      end
    end
  end

  describe "payments" do
    let(:payment_method) { create(:payment_method) }
    let(:shipping_method) { create(:shipping_method) }
    let(:order) { create(:order_with_totals_and_distribution) }

    before { order.update_totals }

    context "when the order is not a subscription" do
      it "it requires a payment" do
        expect(order.payment_required?).to be true
      end

      it "advances to payment state" do
        advance_to_delivery_state(order)

        expect { order.next! }.to change { order.state }.from("delivery").to("payment")
      end

      # Regression test for https://github.com/openfoodfoundation/openfoodnetwork/issues/3924
      it "advances to complete state without error" do
        advance_to_delivery_state(order)
        order.next!
        order.payments << create(:payment, order:)

        expect { order.next! }.to change { order.state }.from("payment").to("confirmation")
        expect { order.next! }.to change { order.state }.from("confirmation").to("complete")
      end
    end

    context "when the order is a subscription" do
      let!(:proxy_order) { create(:proxy_order, order:) }
      let!(:order_cycle) { proxy_order.order_cycle }

      context "and order_cycle has no order_close_at set" do
        before { order.order_cycle.update(orders_close_at: nil) }

        it "requires a payment" do
          expect(order.payment_required?).to be true
        end
      end

      context "and the order_cycle has closed" do
        before { order.order_cycle.update(orders_close_at: 5.minutes.ago) }

        it "returns the payments on the order" do
          expect(order.payment_required?).to be true
        end
      end

      context "and the order_cycle has not yet closed" do
        before { order.order_cycle.update(orders_close_at: 5.minutes.from_now) }

        it "returns an empty array" do
          expect(order.payment_required?).to be false
        end

        it "skips the payment state" do
          advance_to_delivery_state(order)

          expect { order.next! }.to change { order.state }.from("delivery").to("confirmation")
          expect { order.next! }.to change { order.state }.from("confirmation").to("complete")
        end
      end
    end

    def advance_to_delivery_state(order)
      # advance to address state
      order.ship_address = create(:address)
      order.next!
      expect(order.state).to eq "address"

      # advance to delivery state
      order.next!
      expect(order.state).to eq "delivery"
    end
  end

  describe '#restart_checkout!' do
    context 'when the order is complete' do
      let(:order) do
        build_stubbed(
          :order,
          completed_at: Time.zone.now,
          line_items: [build_stubbed(:line_item)]
        )
      end

      it 'raises' do
        expect { order.restart_checkout! }
          .to raise_error(StateMachines::InvalidTransition)
      end
    end

    context 'when the order is not complete' do
      let(:order) do
        build(:order, completed_at: nil, line_items: [build(:line_item)])
      end

      it 'transitions to :cart state' do
        order.restart_checkout!
        expect(order.state).to eq('cart')
      end
    end
  end

  describe "#ensure_updated_shipments" do
    before { Spree::Shipment.create!(order:) }

    context "when the order is not completed" do
      it "destroys current shipments" do
        order.ensure_updated_shipments
        expect(order.shipments).to be_empty
      end

      it "puts order back in address state" do
        order.ensure_updated_shipments
        expect(order.state).to eq "address"
      end
    end

    context "when the order is completed" do
      before do
        allow(order).to receive(:completed?) { true }
      end

      it "does not change the shipments" do
        expect {
          order.ensure_updated_shipments
        }.not_to change { order.shipments }

        expect {
          order.ensure_updated_shipments
        }.not_to change { order.state }
      end
    end
  end

  describe "#sort_line_items" do
    let(:aaron) { create(:supplier_enterprise, name: "Aaron the farmer") }
    let(:zed) { create(:supplier_enterprise, name: "Zed the farmer") }

    let(:aaron_apple) { create(:product, name: "Apple", supplier_id: aaron.id) }
    let(:aaron_banana) { create(:product, name: "Banana", supplier_id: aaron.id) }
    let(:zed_apple) { create(:product, name: "Apple", supplier_id: zed.id) }
    let(:zed_banana) { create(:product, name: "Banana", supplier_id: zed.id) }

    let(:distributor) { create(:distributor_enterprise) }
    let(:order) do
      create(:order, distributor:).tap do |order|
        order.line_items << build(:line_item, variant: aaron_apple.variants.first)
        order.line_items << build(:line_item, variant: zed_banana.variants.first)
        order.line_items << build(:line_item, variant: zed_apple.variants.first)
        order.line_items << build(:line_item, variant: aaron_banana.variants.first)
      end
    end

    let(:line_item_names) do
      order.sorted_line_items.map do |item|
        "#{item.product.name} - #{item.supplier.name}"
      end
    end

    context "when the distributor has preferred_invoice_order_by_supplier set to true" do
      it "sorts the line items by supplier" do
        distributor.update_attribute(:preferred_invoice_order_by_supplier, true)

        expect(line_item_names).to eq [
          "Apple - Aaron the farmer",
          "Banana - Aaron the farmer",
          "Apple - Zed the farmer",
          "Banana - Zed the farmer",
        ]
      end
    end

    context "when the distributor has preferred_invoice_order_by_supplier set to false" do
      it "sorts the line items by product" do
        distributor.update_attribute(:preferred_invoice_order_by_supplier, false)

        expect(line_item_names).to eq [
          "Apple - Aaron the farmer",
          "Apple - Zed the farmer",
          "Banana - Zed the farmer",
          "Banana - Aaron the farmer",
        ]
      end
    end
  end

  describe "#voucher_adjustments" do
    let(:distributor) { create(:distributor_enterprise) }
    let(:order) { create(:order, user:, distributor:) }
    let(:voucher) { create(:voucher_flat_rate, code: 'new_code', enterprise: order.distributor) }

    context "when no voucher adjustment" do
      it 'returns an empty array' do
        expect(order.voucher_adjustments).to eq([])
      end
    end

    it "returns an array of voucher adjusment" do
      expected_adjustments = Array.new(2) { voucher.create_adjustment(voucher.code, order) }

      expect(order.voucher_adjustments).to eq(expected_adjustments)
    end
  end

  describe '#applied_voucher_rate' do
    let(:distributor) { create(:distributor_enterprise) }
    let(:order) { create(:order, user:, distributor:) }

    context 'when the order has no voucher adjustment' do
      it 'returns the BigDecimal 0 value' do
        actual = order.applied_voucher_rate
        expect(actual.class).to eq(BigDecimal)
        # below expectation gets passed if 0 (Integer) is returned regardless of BigDecimal 0
        # Hence adding the expectation for the class as well
        expect(actual).to eq(BigDecimal(0))
      end
    end

    context "given that the order has voucher adjustment and pre_discount_total is 20" do
      before do
        voucher.create_adjustment(voucher.code, order)
        allow(order).to receive(:pre_discount_total).and_return(BigDecimal(20))
      end

      context "when order has voucher_flat_rate adjustment" do
        let(:voucher) { create(:voucher_flat_rate, enterprise: order.distributor, amount: 10) }

        it 'returns the BigDecimal 0 value' do
          actual = order.applied_voucher_rate
          expect(actual.class).to eq(BigDecimal)
          # below expectation gets passed if 0 (Integer) is returned regardless of BigDecimal 0
          # Hence adding the expectation for the class as well
          expect(actual).to eq(-BigDecimal('0.5'))
        end
      end

      context "when order has voucher_percentage_rate adjustment" do
        let(:voucher) do
          create(:voucher_percentage_rate, enterprise: order.distributor, amount: 10)
        end

        it 'returns the BigDecimal 0 value' do
          actual = order.applied_voucher_rate
          expect(actual.class).to eq(BigDecimal)
          # below expectation gets passed if 0 (Integer) is returned regardless of BigDecimal 0
          # Hence adding the expectation for the class as well
          expect(actual).to eq(-BigDecimal('0.1'))
        end
      end
    end
  end
end
