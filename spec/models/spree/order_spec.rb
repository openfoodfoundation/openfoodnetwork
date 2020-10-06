require 'spec_helper'

describe Spree::Order do
  include OpenFoodNetwork::EmailHelper

  describe "email validation" do
    let(:order) { build(:order) }

    it "has errors if email is blank" do
      order.stub(require_email: true)
      order.email = ""

      order.valid?
      expect(order.errors[:email]).to eq ["can't be blank", "is invalid"]
    end

    it "has errors if email is invalid" do
      order.stub(require_email: true)
      order.email = "invalid_email"

      order.valid?
      expect(order.errors[:email]).to eq ["is invalid"]
    end

    it "has errors if email has invalid domain" do
      order.stub(require_email: true)
      order.email = "single_letter_tld@domain.z"

      order.valid?
      expect(order.errors[:email]).to eq ["is invalid"]
    end

    it "is valid if email is valid" do
      order.stub(require_email: true)
      order.email = "a@b.ca"

      order.valid?
      expect(order.errors[:email]).to eq []
    end
  end

  describe "setting variant attributes" do
    it "sets attributes on line items for variants" do
      d = create(:distributor_enterprise)
      p = create(:product)

      subject.distributor = d
      subject.save!

      subject.add_variant(p.master, 1, 3)

      li = Spree::LineItem.last
      expect(li.max_quantity).to eq(3)
    end

    it "does nothing when the line item is not found" do
      p = build_stubbed(:simple_product)
      subject.set_variant_attributes(p.master, { 'max_quantity' => '3' }.with_indifferent_access)
    end
  end

  describe "updating the distribution charge" do
    let(:order) { build(:order) }

    it "clears all enterprise fee adjustments on the order" do
      expect(EnterpriseFee).to receive(:clear_all_adjustments_on_order).with(subject)
      subject.update_distribution_charge!
    end

    it "skips order cycle per-order adjustments for orders that don't have an order cycle" do
      allow(EnterpriseFee).to receive(:clear_all_adjustments_on_order)

      allow(subject).to receive(:order_cycle) { nil }

      subject.update_distribution_charge!
    end

    it "ensures the correct adjustment(s) are created for order cycles" do
      allow(EnterpriseFee).to receive(:clear_all_adjustments_on_order)
      line_item = create(:line_item, order: subject)
      allow(subject).to receive(:provided_by_order_cycle?) { true }

      order_cycle = double(:order_cycle)
      expect_any_instance_of(OpenFoodNetwork::EnterpriseFeeCalculator).
        to receive(:create_line_item_adjustments_for).
        with(line_item)
      allow_any_instance_of(OpenFoodNetwork::EnterpriseFeeCalculator).to receive(:create_order_adjustments_for)
      allow(subject).to receive(:order_cycle) { order_cycle }

      subject.update_distribution_charge!
    end

    it "ensures the correct per-order adjustment(s) are created for order cycles" do
      allow(EnterpriseFee).to receive(:clear_all_adjustments_on_order)

      order_cycle = double(:order_cycle)
      expect_any_instance_of(OpenFoodNetwork::EnterpriseFeeCalculator).
        to receive(:create_order_adjustments_for).
        with(subject)

      allow(subject).to receive(:order_cycle) { order_cycle }

      subject.update_distribution_charge!
    end
  end

  describe "looking up whether a line item can be provided by an order cycle" do
    it "returns true when the variant is provided" do
      v = double(:variant)
      line_item = double(:line_item, variant: v)
      order_cycle = double(:order_cycle, variants: [v])
      allow(subject).to receive(:order_cycle) { order_cycle }

      expect(subject.send(:provided_by_order_cycle?, line_item)).to be true
    end

    it "returns false otherwise" do
      v = double(:variant)
      line_item = double(:line_item, variant: v)
      order_cycle = double(:order_cycle, variants: [])
      allow(subject).to receive(:order_cycle) { order_cycle }

      expect(subject.send(:provided_by_order_cycle?, line_item)).to be false
    end

    it "returns false when there is no order cycle" do
      v = double(:variant)
      line_item = double(:line_item, variant: v)
      allow(subject).to receive(:order_cycle) { nil }

      expect(subject.send(:provided_by_order_cycle?, line_item)).to be false
    end
  end

  describe "getting the admin and handling charge" do
    let(:o) { create(:order) }
    let(:li) { create(:line_item, order: o) }

    it "returns the sum of eligible enterprise fee adjustments" do
      ef = create(:enterprise_fee, calculator: Calculator::FlatRate.new )
      ef.calculator.set_preference :amount, 123.45
      a = ef.create_adjustment("adjustment", o, o, true)

      expect(o.admin_and_handling_total).to eq(123.45)
    end

    it "does not include ineligible adjustments" do
      ef = create(:enterprise_fee, calculator: Calculator::FlatRate.new )
      ef.calculator.set_preference :amount, 123.45
      a = ef.create_adjustment("adjustment", o, o, true)

      a.update_column :eligible, false

      expect(o.admin_and_handling_total).to eq(0)
    end

    it "does not include adjustments that do not originate from enterprise fees" do
      sm = create(:shipping_method, calculator: Calculator::FlatRate.new )
      sm.calculator.set_preference :amount, 123.45
      sm.create_adjustment("adjustment", o, o, true)

      expect(o.admin_and_handling_total).to eq(0)
    end

    it "does not include adjustments whose source is a line item" do
      ef = create(:enterprise_fee, calculator: Calculator::PerItem.new )
      ef.calculator.set_preference :amount, 123.45
      ef.create_adjustment("adjustment", li.order, li, true)

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
    let(:shipping_method) { create(:shipping_method_with, :flat_rate) }

    context "with a taxed shipment" do
      before do
        allow(Spree::Config).to receive(:shipment_inc_vat).and_return(true)
        allow(Spree::Config).to receive(:shipping_tax_rate).and_return(0.25)
      end

      let!(:shipment) { create(:shipment_with, :shipping_method, shipping_method: shipping_method, order: order) }

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

  describe "getting the enterprise fee tax" do
    let!(:order) { create(:order) }
    let(:enterprise_fee1) { create(:enterprise_fee) }
    let(:enterprise_fee2) { create(:enterprise_fee) }
    let!(:adjustment1) { create(:adjustment, adjustable: order, originator: enterprise_fee1, label: "EF 1", amount: 123, included_tax: 10.00) }
    let!(:adjustment2) { create(:adjustment, adjustable: order, originator: enterprise_fee2, label: "EF 2", amount: 123, included_tax: 2.00) }

    it "returns a sum of the tax included in all enterprise fees" do
      expect(order.reload.enterprise_fee_tax).to eq(12)
    end
  end

  describe "getting the total tax" do
    before do
      allow(Spree::Config).to receive(:shipment_inc_vat).and_return(true)
      allow(Spree::Config).to receive(:shipping_tax_rate).and_return(0.25)
    end

    let(:order) { create(:order) }
    let(:shipping_method) { create(:shipping_method_with, :flat_rate) }
    let!(:shipment) do
      create(:shipment_with, :shipping_method, shipping_method: shipping_method, order: order)
    end
    let(:enterprise_fee) { create(:enterprise_fee) }

    before do
      create(
        :adjustment,
        adjustable: order,
        originator: enterprise_fee,
        label: "EF",
        amount: 123,
        included_tax: 2
      )
      order.reload
    end

    it "returns a sum of all tax on the order" do
      # 12 = 2 (of the enterprise fee adjustment) + 10 (of the shipment adjustment)
      expect(order.total_tax).to eq(12)
    end
  end

  describe "setting the distributor" do
    it "sets the distributor when no order cycle is set" do
      d = create(:distributor_enterprise)
      subject.set_distributor! d
      expect(subject.distributor).to eq(d)
    end

    it "keeps the order cycle when it is available at the new distributor" do
      d = create(:distributor_enterprise)
      oc = create(:simple_order_cycle)
      create(:exchange, order_cycle: oc, sender: oc.coordinator, receiver: d, incoming: false)

      subject.order_cycle = oc
      subject.set_distributor! d

      expect(subject.distributor).to eq(d)
      expect(subject.order_cycle).to eq(oc)
    end

    it "clears the order cycle if it is not available at that distributor" do
      d = create(:distributor_enterprise)
      oc = create(:simple_order_cycle)

      subject.order_cycle = oc
      subject.set_distributor! d

      expect(subject.distributor).to eq(d)
      expect(subject.order_cycle).to be_nil
    end

    it "clears the distributor when setting to nil" do
      d = create(:distributor_enterprise)
      subject.set_distributor! d
      subject.set_distributor! nil

      expect(subject.distributor).to be_nil
    end
  end

  describe "removing an item from the order" do
    let(:order) { create(:order) }
    let(:v1)    { create(:variant) }
    let(:v2)    { create(:variant) }
    let(:v3)    { create(:variant) }

    before do
      order.add_variant v1
      order.add_variant v2

      order.update_distribution_charge!
    end

    it "removes the variant's line item" do
      order.remove_variant v1
      expect(order.line_items(:reload).map(&:variant)).to eq([v2])
    end

    it "does nothing when there is no matching line item" do
      expect do
        order.remove_variant v3
      end.to change(order.line_items(:reload), :count).by(0)
    end

    context "when the item has an associated adjustment" do
      let(:distributor) { create(:distributor_enterprise) }

      let(:order_cycle) do
        create(:order_cycle).tap do
          create(:exchange, variants: [v1], incoming: true)
          create(:exchange, variants: [v1], incoming: false, receiver: distributor)
        end
      end

      let(:order) { create(:order, distributor: distributor, order_cycle: order_cycle) }

      it "removes the variant's line item" do
        order.remove_variant v1
        expect(order.line_items(:reload).map(&:variant)).to eq([v2])
      end

      it "removes the variant's adjustment" do
        line_item = order.line_items.where(variant_id: v1.id).first
        adjustment_scope = Spree::Adjustment.where(source_type: "Spree::LineItem",
                                                   source_id: line_item.id)
        expect(adjustment_scope.count).to eq(1)
        adjustment = adjustment_scope.first
        order.remove_variant v1
        expect { adjustment.reload }.to raise_error
      end
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
      subject.set_order_cycle! oc
    end

    it "doesn't empty the cart if the order cycle is not different" do
      expect(subject).not_to receive(:empty!)
      subject.set_order_cycle! subject.order_cycle
    end

    it "sets the order cycle when no distributor is set" do
      subject.set_order_cycle! oc
      expect(subject.order_cycle).to eq(oc)
    end

    it "keeps the distributor when it is available in the new order cycle" do
      d = create(:distributor_enterprise)
      create(:exchange, order_cycle: oc, sender: oc.coordinator, receiver: d, incoming: false)

      subject.distributor = d
      subject.set_order_cycle! oc

      expect(subject.order_cycle).to eq(oc)
      expect(subject.distributor).to eq(d)
    end

    it "clears the distributor if it is not available at that order cycle" do
      d = create(:distributor_enterprise)

      subject.distributor = d
      subject.set_order_cycle! oc

      expect(subject.order_cycle).to eq(oc)
      expect(subject.distributor).to be_nil
    end

    it "clears the order cycle when setting to nil" do
      d = create(:distributor_enterprise)
      subject.set_order_cycle! oc
      subject.distributor = d

      subject.set_order_cycle! nil

      expect(subject.order_cycle).to be_nil
      expect(subject.distributor).to eq(d)
    end
  end

  context "change distributor and order cycle" do
    let(:variant1) { create(:product).variants.first }
    let(:variant2) { create(:product).variants.first }
    let(:distributor) { create(:enterprise) }

    before do
      subject.order_cycle = create(:simple_order_cycle, distributors: [distributor], variants: [variant1, variant2])
      subject.distributor = distributor

      line_item1 = create(:line_item, order: subject, variant: variant1)
      line_item2 = create(:line_item, order: subject, variant: variant2)
      subject.reload
      subject.line_items = [line_item1, line_item2]
    end

    it "allows the change when all variants in the order are provided by the new distributor in the new order cycle" do
      new_distributor = create(:enterprise)
      new_order_cycle = create(:simple_order_cycle, distributors: [new_distributor], variants: [variant1, variant2])

      subject.distributor = new_distributor
      expect(subject).not_to be_valid
      subject.order_cycle = new_order_cycle
      expect(subject).to be_valid
    end

    it "does not allow the change when not all variants in the order are provided by the new distributor" do
      new_distributor = create(:enterprise)
      create(:simple_order_cycle, distributors: [new_distributor], variants: [variant1])

      subject.distributor = new_distributor
      expect(subject).not_to be_valid
      expect(subject.errors.messages).to eq(base: ["Distributor or order cycle cannot supply the products in your cart"])
    end
  end

  describe "scopes" do
    describe "not_state" do
      before do
        setup_email
      end

      it "finds only orders not in specified state" do
        o = FactoryBot.create(:completed_order_with_totals, distributor: create(:distributor_enterprise))
        o.cancel!
        expect(Spree::Order.not_state(:canceled)).not_to include o
      end
    end
  end

  describe "sending confirmation emails" do
    let!(:distributor) { create(:distributor_enterprise) }
    let!(:order) { create(:order, distributor: distributor) }

    it "sends confirmation emails" do
      expect do
        order.deliver_order_confirmation_email
      end.to enqueue_job ConfirmOrderJob
    end

    it "does not send confirmation emails when the order belongs to a subscription" do
      create(:proxy_order, order: order)

      expect do
        order.deliver_order_confirmation_email
      end.to_not enqueue_job ConfirmOrderJob
    end
  end

  describe "associating a customer" do
    let(:distributor) { create(:distributor_enterprise) }
    let!(:order) { create(:order, distributor: distributor) }

    context "when an email address is available for the order" do
      before { allow(order).to receive(:email_for_customer) { "existing@email.com" } }

      context "and a customer for order.distributor and order#email_for_customer already exists" do
        let!(:customer) { create(:customer, enterprise: distributor, email: "existing@email.com" ) }

        it "associates the order with the existing customer, and returns the customer" do
          result = order.send(:associate_customer)
          expect(order.customer).to eq customer
          expect(result).to eq customer
        end
      end

      context "and a customer for order.distributor and order.user.email does not alread exist" do
        let!(:customer) { create(:customer, enterprise: distributor, email: 'some-other-email@email.com') }

        it "does not set the customer and returns nil" do
          result = order.send(:associate_customer)
          expect(order.customer).to be_nil
          expect(result).to be_nil
        end
      end
    end

    context "when an email address is not available for the order" do
      let!(:customer) { create(:customer, enterprise: distributor) }
      before { allow(order).to receive(:email_for_customer) { nil } }

      it "does not set the customer and returns nil" do
        result = order.send(:associate_customer)
        expect(order.customer).to be_nil
        expect(result).to be_nil
      end
    end
  end

  describe "ensuring a customer is linked" do
    let(:distributor) { create(:distributor_enterprise) }
    let!(:order) { create(:order, distributor: distributor) }

    context "when a customer has already been linked to the order" do
      let!(:customer) { create(:customer, enterprise: distributor, email: "existing@email.com" ) }
      before { order.update_attribute(:customer_id, customer.id) }

      it "does nothing" do
        order.send(:ensure_customer)
        expect(order.customer).to eq customer
      end
    end

    context "when a customer not been linked to the order" do
      context "but one matching order#email_for_customer already exists" do
        let!(:customer) { create(:customer, enterprise: distributor, email: 'some-other-email@email.com') }
        before { allow(order).to receive(:email_for_customer) { 'some-other-email@email.com' } }

        it "links the customer customer to the order" do
          expect(order.customer).to be_nil
          expect{ order.send(:ensure_customer) }.to_not change{ Customer.count }
          expect(order.customer).to eq customer
        end
      end

      context "and order#email_for_customer does not match any existing customers" do
        before {
          order.bill_address = create(:address)
          order.ship_address = create(:address)
        }
        it "creates a new customer with defaut name and addresses" do
          expect(order.customer).to be_nil
          expect{ order.send(:ensure_customer) }.to change{ Customer.count }.by 1
          expect(order.customer).to be_a Customer

          expect(order.customer.name).to eq order.bill_address.full_name
          expect(order.customer.bill_address.same_as?(order.bill_address)).to be true
          expect(order.customer.ship_address.same_as?(order.ship_address)).to be true
        end
      end
    end
  end

  describe "when a guest order is placed with a registered email" do
    let(:order) { create(:order_with_totals_and_distribution, user: user) }
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
      expect{ order.next }.to change(order.errors, :count).from(0).to(1)
      expect(order.errors.messages[:base]).to eq [I18n.t('devise.failure.already_registered')]
      expect(order.state).to eq 'cart'
    end
  end

  describe "a completed order with shipping and transaction fees" do
    let(:distributor) { create(:distributor_enterprise_with_tax) }
    let(:order) { create(:completed_order_with_fees, distributor: distributor, shipping_fee: shipping_fee, payment_fee: payment_fee) }
    let(:shipping_fee) { 3 }
    let(:payment_fee) { 5 }
    let(:item_num) { order.line_items.length }
    let(:expected_fees) { item_num * (shipping_fee + payment_fee) }

    before do
      Spree::Config.shipment_inc_vat = true
      Spree::Config.shipping_tax_rate = 0.25

      # Sanity check the fees
      expect(order.adjustments.length).to eq 2
      expect(item_num).to eq 2
      expect(order.adjustment_total).to eq expected_fees
      expect(order.shipment.adjustment.included_tax).to eq 1.2
    end

    context "removing line_items" do
      it "updates shipping and transaction fees" do
        order.line_items.first.update_attribute(:quantity, 0)
        order.save

        expect(order.adjustment_total).to eq expected_fees - shipping_fee - payment_fee
        expect(order.shipment.adjustment.included_tax).to eq 0.6
      end

      context "when finalized fee adjustments exist on the order" do
        let(:payment_fee_adjustment) { order.adjustments.payment_fee.first }
        let(:shipping_fee_adjustment) { order.adjustments.shipping.first }

        before do
          payment_fee_adjustment.finalize!
          shipping_fee_adjustment.finalize!
          order.reload
        end

        it "does not attempt to update such adjustments" do
          order.update(line_items_attributes: [{ id: order.line_items.first.id, quantity: 0 }])

          # Check if fees got updated
          order.reload
          expect(order.adjustment_total).to eq expected_fees
          expect(order.shipment.adjustment.included_tax).to eq 1.2
        end
      end
    end

    context "changing the shipping method to one without fees" do
      let(:shipping_method) { create(:shipping_method, calculator: Calculator::FlatRate.new(preferred_amount: 0)) }

      it "updates shipping fees" do
        order.shipments = [create(:shipment_with, :shipping_method, shipping_method: shipping_method)]
        order.save

        expect(order.adjustment_total).to eq expected_fees - (item_num * shipping_fee)
        expect(order.shipment.adjustment.included_tax).to eq 0
      end
    end

    context "changing the payment method to one without fees" do
      let(:payment_method) { create(:payment_method, calculator: Calculator::FlatRate.new(preferred_amount: 0)) }

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
    let!(:order) { create(:order, distributor: distributor, order_cycle: order_cycle) }

    it "returns no items if nothing has been ordered" do
      expect(order.finalised_line_items).to eq []
    end

    context "when no order has been finalised in this order cycle" do
      let(:product) { create(:product) }

      it "returns no items even though the cart contains items" do
        order.add_variant(product.master, 1, 3)
        expect(order.finalised_line_items).to eq []
      end
    end

    context "when an order has been finalised in this order cycle" do
      let!(:prev_order) { create(:completed_order_with_totals, distributor: distributor, order_cycle: order_cycle, user: order.user) }
      let!(:prev_order2) { create(:completed_order_with_totals, distributor: distributor, order_cycle: order_cycle, user: order.user) }
      let(:product) { create(:product) }

      it "returns previous items" do
        prev_order.add_variant(product.master, 1, 3)
        prev_order2.reload # to get the right response from line_items
        expect(order.finalised_line_items.length).to eq 11
        expect(order.finalised_line_items).to match_array(prev_order.line_items + prev_order2.line_items)
      end
    end
  end

  describe "determining checkout steps for an order" do
    let!(:enterprise) { create(:enterprise) }
    let!(:order) { create(:order, distributor: enterprise) }
    let!(:payment_method) { create(:stripe_connect_payment_method, distributor_ids: [enterprise.id]) }
    let!(:payment) { create(:payment, order: order, payment_method: payment_method) }

    it "does not include the :confirm step" do
      expect(order.checkout_steps).to_not include "confirm"
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

      it "advances to complete state despite error" do
        advance_to_delivery_state(order)
        # advance to payment state
        order.next!

        create(:payment, order: order)
        # https://github.com/openfoodfoundation/openfoodnetwork/issues/3924
        observed_error = ActiveRecord::RecordNotUnique.new(
          "PG::UniqueViolation",
          StandardError.new
        )
        expect(order.shipment).to receive(:save).and_call_original
        expect(order.shipment).to receive(:save).and_call_original
        expect(order.shipment).to receive(:save).and_raise(observed_error)

        expect { order.next! }.to change { order.state }.from("payment").to("complete")
      end
    end

    context "when the order is a subscription" do
      let!(:proxy_order) { create(:proxy_order, order: order) }
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

          expect { order.next! }.to change { order.state }.from("delivery").to("complete")
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
          .to raise_error(StateMachine::InvalidTransition)
      end
    end

    context 'when the is not complete' do
      let(:order) do
        build(
          :order,
          completed_at: nil,
          line_items: [build(:line_item)]
        )
      end

      it 'transitions to :cart state' do
        order.restart_checkout!
        expect(order.state).to eq('cart')
      end
    end
  end

  describe '#charge_shipping_and_payment_fees!' do
    let(:order) do
      shipment = build(:shipment_with, :shipping_method, shipping_method: build(:shipping_method))
      build(:order, shipments: [shipment] )
    end

    context 'after transitioning to payment' do
      before do
        order.state = 'delivery' # payment's previous state

        allow(order).to receive(:payment_required?) { true }
      end

      it 'calls charge_shipping_and_payment_fees! and updates totals' do
        expect(order).to receive(:charge_shipping_and_payment_fees!)
        expect(order).to receive(:update_totals).at_least(:once)

        order.next
      end

      context "payment's amount" do
        let(:failed_payment) { create(:payment, order: order, state: 'failed', amount: 100) }

        before do
          allow(order).to receive(:total) { 120 }
        end

        it 'is not updated for failed payments' do
          failed_payment

          order.next

          expect(failed_payment.reload.amount).to eq 100
        end

        it 'is updated only for pending payments' do
          pending_payment = create(:payment, order: order, state: 'pending', amount: 80)
          failed_payment

          order.next

          expect(failed_payment.reload.amount).to eq 100
          expect(pending_payment.reload.amount).to eq 120
        end
      end
    end
  end
end
