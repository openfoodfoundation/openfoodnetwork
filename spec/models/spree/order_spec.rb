require 'spec_helper'

describe Spree::Order do
  describe "setting variant attributes" do
    it "sets attributes on line items for variants" do
      d = create(:distributor_enterprise)
      p = create(:product, :distributors => [d])

      subject.distributor = d
      subject.save!

      subject.add_variant(p.master, 1, 3)

      li = Spree::LineItem.last
      li.max_quantity.should == 3
    end

    it "does nothing when the line item is not found" do
      p = create(:simple_product)
      subject.set_variant_attributes(p.master, {'max_quantity' => '3'}.with_indifferent_access)
    end
  end

  describe "updating the distribution charge" do
    let(:order) { build(:order) }

    it "clears all enterprise fee adjustments on the order" do
      EnterpriseFee.should_receive(:clear_all_adjustments_on_order).with(subject)
      subject.update_distribution_charge!
    end

    it "ensures the correct adjustment(s) are created for the product distribution" do
      EnterpriseFee.stub(:clear_all_adjustments_on_order)
      line_item = double(:line_item)
      subject.stub(:line_items) { [line_item] }
      subject.stub(:provided_by_order_cycle?) { false }

      product_distribution = double(:product_distribution)
      product_distribution.should_receive(:create_adjustment_for).with(line_item)
      subject.stub(:product_distribution_for) { product_distribution }


      subject.update_distribution_charge!
    end

    it "skips line items that don't have a product distribution" do
      EnterpriseFee.stub(:clear_all_adjustments_on_order)
      line_item = double(:line_item)
      subject.stub(:line_items) { [line_item] }
      subject.stub(:provided_by_order_cycle?) { false }

      subject.stub(:product_distribution_for) { nil }

      subject.update_distribution_charge!
    end

    it "skips order cycle per-order adjustments for orders that don't have an order cycle" do
      EnterpriseFee.stub(:clear_all_adjustments_on_order)
      subject.stub(:line_items) { [] }

      subject.stub(:order_cycle) { nil }

      subject.update_distribution_charge!
    end

    it "ensures the correct adjustment(s) are created for order cycles" do
      EnterpriseFee.stub(:clear_all_adjustments_on_order)
      line_item = double(:line_item)
      subject.stub(:line_items) { [line_item] }
      subject.stub(:provided_by_order_cycle?) { true }

      order_cycle = double(:order_cycle)
      OpenFoodNetwork::EnterpriseFeeCalculator.any_instance.
        should_receive(:create_line_item_adjustments_for).
        with(line_item)
      OpenFoodNetwork::EnterpriseFeeCalculator.any_instance.stub(:create_order_adjustments_for)
      subject.stub(:order_cycle) { order_cycle }

      subject.update_distribution_charge!
    end

    it "ensures the correct per-order adjustment(s) are created for order cycles" do
      EnterpriseFee.stub(:clear_all_adjustments_on_order)
      subject.stub(:line_items) { [] }

      order_cycle = double(:order_cycle)
      OpenFoodNetwork::EnterpriseFeeCalculator.any_instance.
        should_receive(:create_order_adjustments_for).
        with(subject)

      subject.stub(:order_cycle) { order_cycle }

      subject.update_distribution_charge!
    end
  end

  describe "looking up whether a line item can be provided by an order cycle" do
    it "returns true when the variant is provided" do
      v = double(:variant)
      line_item = double(:line_item, variant: v)
      order_cycle = double(:order_cycle, variants: [v])
      subject.stub(:order_cycle) { order_cycle }

      subject.send(:provided_by_order_cycle?, line_item).should be true
    end

    it "returns false otherwise" do
      v = double(:variant)
      line_item = double(:line_item, variant: v)
      order_cycle = double(:order_cycle, variants: [])
      subject.stub(:order_cycle) { order_cycle }

      subject.send(:provided_by_order_cycle?, line_item).should be false
    end

    it "returns false when there is no order cycle" do
      v = double(:variant)
      line_item = double(:line_item, variant: v)
      subject.stub(:order_cycle) { nil }

      subject.send(:provided_by_order_cycle?, line_item).should be false
    end
  end

  it "looks up product distribution enterprise fees for a line item" do
    product = double(:product)
    variant = double(:variant, product: product)
    line_item = double(:line_item, variant: variant)

    product_distribution = double(:product_distribution)
    product.should_receive(:product_distribution_for).with(subject.distributor) { product_distribution }

    subject.send(:product_distribution_for, line_item).should == product_distribution
  end

  describe "getting the admin and handling charge" do
    let(:o) { create(:order) }
    let(:li) { create(:line_item, order: o) }

    it "returns the sum of eligible enterprise fee adjustments" do
      ef = create(:enterprise_fee, calculator: Spree::Calculator::FlatRate.new )
      ef.calculator.set_preference :amount, 123.45
      a = ef.create_adjustment("adjustment", o, o, true)

      o.admin_and_handling_total.should == 123.45
    end

    it "does not include ineligible adjustments" do
      ef = create(:enterprise_fee, calculator: Spree::Calculator::FlatRate.new )
      ef.calculator.set_preference :amount, 123.45
      a = ef.create_adjustment("adjustment", o, o, true)

      a.update_column :eligible, false

      o.admin_and_handling_total.should == 0
    end

    it "does not include adjustments that do not originate from enterprise fees" do
      sm = create(:shipping_method, calculator: Spree::Calculator::FlatRate.new )
      sm.calculator.set_preference :amount, 123.45
      sm.create_adjustment("adjustment", o, o, true)

      o.admin_and_handling_total.should == 0
    end

    it "does not include adjustments whose source is a line item" do
      ef = create(:enterprise_fee, calculator: Spree::Calculator::PerItem.new )
      ef.calculator.set_preference :amount, 123.45
      ef.create_adjustment("adjustment", li.order, li, true)

      o.admin_and_handling_total.should == 0
    end
  end

  describe "an order without shipping method" do
    let(:order)           { create(:order) }

    it "cannot be shipped" do
      order.ready_to_ship?.should == false
    end
  end

  describe "an unpaid order with a shipment" do
    let(:order)           { create(:order_with_totals, shipping_method: shipping_method) }
    let(:shipping_method) { create(:shipping_method) }

    before do
      order.create_shipment!
      order.reload
      order.state = 'complete'
      order.shipment.update!(order)
    end

    it "cannot be shipped" do
      order.ready_to_ship?.should == false
    end
  end

  describe "a paid order without a shipment" do
    let(:order)           { create(:order) }

    before do
      order.payment_state = 'paid'
      order.state = 'complete'
    end

    it "cannot be shipped" do
      order.ready_to_ship?.should == false
    end
  end

  describe "a paid order with a shipment" do
    let(:order)           { create(:order, shipping_method: shipping_method) }
    let(:shipping_method) { create(:shipping_method) }

    before do
      order.create_shipment!
      order.payment_state = 'paid'
      order.state = 'complete'
      order.shipment.update!(order)
    end

    it "can be shipped" do
      order.ready_to_ship?.should == true
    end
  end

  describe "getting the shipping tax" do
    let(:order)           { create(:order, shipping_method: shipping_method) }
    let(:shipping_method) { create(:shipping_method, calculator: Spree::Calculator::FlatRate.new(preferred_amount: 50.0)) }

    context "with a taxed shipment" do
      before do
        Spree::Config.shipment_inc_vat = true
        Spree::Config.shipping_tax_rate = 0.25
        order.create_shipment!
      end

      it "returns the shipping tax" do
        order.shipping_tax.should == 10
      end
    end

    it "returns zero when the order has not been shipped" do
      order.shipping_tax.should == 0
    end
  end

  describe "getting the enterprise fee tax" do
    let!(:order) { create(:order) }
    let(:enterprise_fee1) { create(:enterprise_fee) }
    let(:enterprise_fee2) { create(:enterprise_fee) }
    let!(:adjustment1) { create(:adjustment, adjustable: order, originator: enterprise_fee1, label: "EF 1", amount: 123, included_tax: 10.00) }
    let!(:adjustment2) { create(:adjustment, adjustable: order, originator: enterprise_fee2, label: "EF 2", amount: 123, included_tax: 2.00) }

    it "returns a sum of the tax included in all enterprise fees" do
      order.reload.enterprise_fee_tax.should == 12
    end
  end

  describe "getting the total tax" do
    let(:order)           { create(:order, shipping_method: shipping_method) }
    let(:shipping_method) { create(:shipping_method, calculator: Spree::Calculator::FlatRate.new(preferred_amount: 50.0)) }
    let(:enterprise_fee)  { create(:enterprise_fee) }
    let!(:adjustment)     { create(:adjustment, adjustable: order, originator: enterprise_fee, label: "EF", amount: 123, included_tax: 2) }

    before do
      Spree::Config.shipment_inc_vat = true
      Spree::Config.shipping_tax_rate = 0.25
      order.create_shipment!
      order.reload
    end

    it "returns a sum of all tax on the order" do
      order.total_tax.should == 12
    end
  end

  describe "getting a hash of all taxes" do
    let(:zone)            { create(:zone_with_member) }
    let(:coordinator)     { create(:distributor_enterprise, charges_sales_tax: true) }

    let(:tax_rate10)      { create(:tax_rate, included_in_price: true, calculator: Spree::Calculator::DefaultTax.new, amount: 0.1, zone: zone) }
    let(:tax_rate15)      { create(:tax_rate, included_in_price: true, calculator: Spree::Calculator::DefaultTax.new, amount: 0.15, zone: zone) }
    let(:tax_rate20)      { create(:tax_rate, included_in_price: true, calculator: Spree::Calculator::DefaultTax.new, amount: 0.2, zone: zone) }
    let(:tax_category10)  { create(:tax_category, tax_rates: [tax_rate10]) }
    let(:tax_category15)  { create(:tax_category, tax_rates: [tax_rate15]) }
    let(:tax_category20)  { create(:tax_category, tax_rates: [tax_rate20]) }

    let(:variant)         { create(:variant, product: create(:product, tax_category: tax_category10)) }
    let(:shipping_method) { create(:shipping_method, calculator: Spree::Calculator::FlatRate.new(preferred_amount: 46.0)) }
    let(:enterprise_fee)  { create(:enterprise_fee, enterprise: coordinator, tax_category: tax_category20, calculator: Spree::Calculator::FlatRate.new(preferred_amount: 48.0)) }

    let(:order_cycle)     { create(:simple_order_cycle, coordinator: coordinator, coordinator_fees: [enterprise_fee], distributors: [coordinator], variants: [variant]) }
    let!(:order)          { create(:order, shipping_method: shipping_method, bill_address: create(:address), order_cycle: order_cycle, distributor: coordinator) }
    let!(:line_item)      { create(:line_item, order: order, variant: variant, price: 44.0) }

    before do
      Spree::Config.shipment_inc_vat = true
      Spree::Config.shipping_tax_rate = tax_rate15.amount
      order.create_shipment!
      Spree::TaxRate.adjust(order)
      order.reload.update_distribution_charge!
    end

    it "returns a hash with all 3 taxes" do
      order.tax_adjustment_totals.size.should == 3
    end

    it "contains tax on line_item" do
      order.tax_adjustment_totals[tax_rate10.amount].should == 4.0
    end

    it "contains tax on shipping_fee" do
      order.tax_adjustment_totals[tax_rate15.amount].should == 6.0
    end

    it "contains tax on enterprise_fee" do
      order.tax_adjustment_totals[tax_rate20.amount].should == 8.0
    end
  end

  describe "setting the distributor" do
    it "sets the distributor when no order cycle is set" do
      d = create(:distributor_enterprise)
      subject.set_distributor! d
      subject.distributor.should == d
    end

    it "keeps the order cycle when it is available at the new distributor" do
      d = create(:distributor_enterprise)
      oc = create(:simple_order_cycle)
      create(:exchange, order_cycle: oc, sender: oc.coordinator, receiver: d, incoming: false)

      subject.order_cycle = oc
      subject.set_distributor! d

      subject.distributor.should == d
      subject.order_cycle.should == oc
    end

    it "clears the order cycle if it is not available at that distributor" do
      d = create(:distributor_enterprise)
      oc = create(:simple_order_cycle)

      subject.order_cycle = oc
      subject.set_distributor! d

      subject.distributor.should == d
      subject.order_cycle.should be_nil
    end

    it "clears the distributor when setting to nil" do
      d = create(:distributor_enterprise)
      subject.set_distributor! d
      subject.set_distributor! nil

      subject.distributor.should be_nil
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
    end

    it "removes the variant's line item" do
      order.remove_variant v1
      order.line_items(:reload).map(&:variant).should == [v2]
    end

    it "does nothing when there is no matching line item" do
      expect do
        order.remove_variant v3
      end.to change(order.line_items(:reload), :count).by(0)
    end
  end

  describe "emptying the order" do
    it "removes shipping method" do
      subject.shipping_method = create(:shipping_method)
      subject.save!
      subject.empty!
      subject.shipping_method.should == nil
    end

    it "removes payments" do
      subject.payments << create(:payment)
      subject.save!
      subject.empty!
      subject.payments.should == []
    end
  end

  describe "setting the order cycle" do
    let(:oc) { create(:simple_order_cycle) }

    it "empties the cart when changing the order cycle" do
      subject.should_receive(:empty!)
      subject.set_order_cycle! oc
    end

    it "doesn't empty the cart if the order cycle is not different" do
      subject.should_not_receive(:empty!)
      subject.set_order_cycle! subject.order_cycle
    end

    it "sets the order cycle when no distributor is set" do
      subject.set_order_cycle! oc
      subject.order_cycle.should == oc
    end

    it "keeps the distributor when it is available in the new order cycle" do
      d = create(:distributor_enterprise)
      create(:exchange, order_cycle: oc, sender: oc.coordinator, receiver: d, incoming: false)

      subject.distributor = d
      subject.set_order_cycle! oc

      subject.order_cycle.should == oc
      subject.distributor.should == d
    end

    it "clears the distributor if it is not available at that order cycle" do
      d = create(:distributor_enterprise)

      subject.distributor = d
      subject.set_order_cycle! oc

      subject.order_cycle.should == oc
      subject.distributor.should be_nil
    end

    it "clears the order cycle when setting to nil" do
      d = create(:distributor_enterprise)
      subject.set_order_cycle! oc
      subject.distributor = d

      subject.set_order_cycle! nil

      subject.order_cycle.should be_nil
      subject.distributor.should == d
    end
  end

  context "validating distributor changes" do
    it "checks that a distributor is available when changing" do
      set_feature_toggle :order_cycles, false
      order_enterprise = FactoryGirl.create(:enterprise, id: 1, :name => "Order Enterprise")
      subject.distributor = order_enterprise
      product1 = FactoryGirl.create(:product)
      product2 = FactoryGirl.create(:product)
      product3 = FactoryGirl.create(:product)
      variant11 = FactoryGirl.create(:variant, product: product1)
      variant12 = FactoryGirl.create(:variant, product: product1)
      variant21 = FactoryGirl.create(:variant, product: product2)
      variant31 = FactoryGirl.create(:variant, product: product3)
      variant32 = FactoryGirl.create(:variant, product: product3)

      # Product Distributions
      # Order Enterprise sells product 1 and product 3
      FactoryGirl.create(:product_distribution, product: product1, distributor: order_enterprise)
      FactoryGirl.create(:product_distribution, product: product3, distributor: order_enterprise)

      # Build the current order
      line_item1 = FactoryGirl.create(:line_item, order: subject, variant: variant11)
      line_item2 = FactoryGirl.create(:line_item, order: subject, variant: variant12)
      line_item3 = FactoryGirl.create(:line_item, order: subject, variant: variant31)
      subject.reload
      subject.line_items = [line_item1,line_item2,line_item3]

      test_enterprise = FactoryGirl.create(:enterprise, id: 2, :name => "Test Enterprise")
      # Test Enterprise sells only product 1
      FactoryGirl.create(:product_distribution, product: product1, distributor: test_enterprise)

      subject.distributor = test_enterprise
      subject.should_not be_valid
      subject.errors.messages.should == {:base => ["Distributor or order cycle cannot supply the products in your cart"]}
    end
  end

  describe "scopes" do
    describe "not_state" do
      before do
        Spree::MailMethod.create!(
          environment: Rails.env,
          preferred_mails_from: 'spree@example.com'
        )
      end

      it "finds only orders not in specified state" do
        o = FactoryGirl.create(:completed_order_with_totals)
        o.cancel!
        Spree::Order.not_state(:canceled).should_not include o
      end
    end
  end

  describe "shipping address prepopulation" do
    let(:distributor) { create(:distributor_enterprise) }
    let(:order) { build(:order, distributor: distributor) }

    before do
      order.ship_address = distributor.address.clone
      order.save # just to trigger our autopopulate the first time ;)
    end

    it "autopopulates the shipping address on save" do
      order.should_receive(:shipping_address_from_distributor).and_return true
      order.save
    end

    it "populates the shipping address if the shipping method doesn't require a delivery address" do
      order.shipping_method = create(:shipping_method, require_ship_address: false)
      order.ship_address.update_attribute :firstname, "will"
      order.save
      order.ship_address.firstname.should == distributor.address.firstname
    end

    it "does not populate the shipping address if the shipping method requires a delivery address" do
      order.shipping_method = create(:shipping_method, require_ship_address: true)
      order.ship_address.update_attribute :firstname, "will"
      order.save
      order.ship_address.firstname.should == "will"
    end

    it "doesn't attempt to create a shipment if the order is not yet valid" do
      order.shipping_method = create(:shipping_method, require_ship_address: false)
      #Shipment.should_not_r
      order.create_shipment!
    end
  end

  describe "checking if an order is an account invoice" do
    let(:accounts_distributor)  { create(:distributor_enterprise) }
    let(:order_account_invoice) { create(:order, distributor: accounts_distributor) }
    let(:order_general)         { create(:order, distributor: create(:distributor_enterprise)) }

    before do
      Spree::Config.accounts_distributor_id = accounts_distributor.id
    end

    it "returns true when the order is distributed by the accounts distributor" do
      order_account_invoice.should be_account_invoice
    end

    it "returns false otherwise" do
      order_general.should_not be_account_invoice
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

    it "does not send confirmation emails when distributor is the accounts_distributor" do
      Spree::Config.set({ accounts_distributor_id: distributor.id })

      expect do
        order.deliver_order_confirmation_email
      end.to_not enqueue_job ConfirmOrderJob
    end

    it "does not send confirmation emails when the order belongs to a standing order" do
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
      before { allow(order).to receive(:email_for_customer) { "existing@email.com" }}

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
      before { allow(order).to receive(:email_for_customer) { nil }}

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
          expect{order.send(:ensure_customer)}.to_not change{Customer.count}
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
          expect{order.send(:ensure_customer)}.to change{Customer.count}.by 1
          expect(order.customer).to be_a Customer

          expect(order.customer.name).to eq order.bill_address.full_name
          expect(order.customer.bill_address.same_as?(order.bill_address)).to be true
          expect(order.customer.ship_address.same_as?(order.ship_address)).to be true
        end
      end
    end
  end

  describe "a completed order with shipping and transaction fees" do
    let(:distributor) { create(:distributor_enterprise, charges_sales_tax: true, allow_order_changes: true) }
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
        # Setting quantity of an item to zero
        order.update_attributes(line_items_attributes: [{id: order.line_items.first.id, quantity: 0}])

        # Check if fees got updated
        order.reload
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
          order.update_attributes(line_items_attributes: [{id: order.line_items.first.id, quantity: 0}])

          # Check if fees got updated
          order.reload
          expect(order.adjustment_total).to eq expected_fees
          expect(order.shipment.adjustment.included_tax).to eq 1.2
        end
      end
    end

    context "changing the shipping method to one without fees" do
      let(:shipping_method) { create(:shipping_method, calculator: Spree::Calculator::FlatRate.new(preferred_amount: 0)) }

      it "updates shipping fees" do
        # Change the shipping method
        order.shipment.update_attributes(shipping_method_id: shipping_method.id)
        order.save

        # Check if fees got updated
        order.reload
        expect(order.adjustment_total).to eq expected_fees - (item_num * shipping_fee)
        expect(order.shipment.adjustment.included_tax).to eq 0
      end
    end

    context "changing the payment method to one without fees" do
      let(:payment_method) { create(:payment_method, calculator: Spree::Calculator::FlatRate.new(preferred_amount: 0)) }

      it "removes transaction fees" do
        # Change the payment method
        order.payments.first.update_attributes(payment_method_id: payment_method.id)
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
        expect(order.finalised_line_items.length).to eq 3
        expect(order.finalised_line_items).to match_array(prev_order.line_items + prev_order2.line_items)
      end
    end
  end

  describe "determining checkout steps for an order" do
    let!(:enterprise) { create(:enterprise) }
    let!(:order) { create(:order, distributor: enterprise) }
    let!(:payment_method) { create(:stripe_payment_method, distributor_ids: [enterprise.id], preferred_enterprise_id: enterprise.id) }
    let!(:payment) { create(:payment, order: order, payment_method: payment_method) }

    it "does not include the :confirm step" do
      expect(order.checkout_steps).to_not include "confirm"
    end
  end

  describe "finding pending_payments" do
    let!(:order) { create(:order ) }
    let!(:payment) { create(:payment, order: order, state: 'checkout') }

    context "when the order is not a standing order" do
      it "returns the payments on the order" do
        expect(order.reload.pending_payments).to eq [payment]
      end
    end

    context "when the order is a standing order" do
      let!(:proxy_order) { create(:proxy_order, order: order) }
      let!(:order_cycle) { proxy_order.order_cycle }

      context "and order_cycle has no order_close_at set" do
        before { order.order_cycle.update_attributes(orders_close_at: nil) }

        it "returns the payments on the order" do
          expect(order.reload.pending_payments).to eq [payment]
        end
      end

      context "and the order_cycle has closed" do
        before { order.order_cycle.update_attributes(orders_close_at: 5.minutes.ago) }

        it "returns the payments on the order" do
          expect(order.reload.pending_payments).to eq [payment]
        end
      end

      context "and the order_cycle has not yet closed" do
        before { order.order_cycle.update_attributes(orders_close_at: 5.minutes.from_now) }

        it "returns an empty array" do
          expect(order.reload.pending_payments).to eq []
        end
      end
    end
  end
end
