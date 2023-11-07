# frozen_string_literal: true

require 'spec_helper'

shared_examples "attribute changes - payment total" do |boolean, type|
  before do
    Spree::Order.where(id: order.id).update_all(payment_total: order.payment_total + 10)
  end

  it "returns #{boolean} if a #{type} attribute changes" do
    order.reload
    expect(subject).to be boolean
  end
end

shared_examples "attribute changes - order total" do |boolean, type|
  before do
    Spree::Order.where(id: order.id).update_all(total: order.total + 10)
  end

  it "returns #{boolean} if a #{type} attribute changes" do
    order.reload
    expect(subject).to be boolean
  end
end

shared_examples "attribute changes - order state: cancelled" do |boolean, type|
  before do
    order.cancel!
  end

  it "returns #{boolean} if a #{type} attribute changes" do
    order.reload
    expect(subject).to be boolean
  end
end

shared_examples "attribute changes - tax total changes" do |boolean, type, included_boolean|
  let(:order) do
    create(:order_with_taxes, product_price: 110, tax_rate_amount: 0.1,
                              included_in_price: included_boolean)
      .tap do |order|
      order.create_tax_charge!
      order.update_shipping_fees!
    end
  end

  context "if included_in_price is #{included_boolean}" do
    before do
      Spree::TaxRate.first.update!(amount: 0.15)
      order.create_tax_charge!
    end

    it "returns #{boolean} if a #{type} attribute changes" do
      order.reload
      expect(subject).to be true
    end
  end
end

shared_examples "attribute changes - shipping method" do |boolean, type|
  let(:shipping_method) { create(:shipping_method) }

  before do
    Spree::ShippingRate.first.update(shipping_method_id: shipping_method.id)
  end

  it "returns #{boolean} if a #{type} attribute changes" do
    order.reload
    expect(subject).to be boolean
  end
end

shared_examples "no attribute changes" do
  it "returns false if no attribute has changed" do
    expect(subject).to be false
  end
end

shared_examples "attribute changes - special insctructions" do |boolean, type|
  before do
    order.update!(special_instructions: "A very special insctruction.")
  end
  it "returns #{boolean} if a #{type} attribute changes" do
    expect(subject).to be boolean
  end
end

shared_examples "attribute changes - note" do |boolean, type|
  before do
    order.update!(note: "THIS IS A NEW NOTE")
  end
  it "returns #{boolean} if a #{type} attribute changes" do
    expect(subject).to be boolean
  end
end

shared_examples "associated attribute changes - adjustments (create)" do |boolean, type|
  context "creating an adjustment" do
    before { order.adjustments << create(:adjustment, order:) }
    it "returns #{boolean} if a #{type} attribute changes" do
      expect(subject).to be boolean
    end
  end

  context "with an existing adjustments" do
    context "editing the amount" do
      before { Spree::Adjustment.first.update!(amount: 123) }
      it "returns #{boolean} if a #{type} attribute changes" do
        expect(subject).to be boolean
      end
    end

    context "changing the adjustment type" do
      before { Spree::Adjustment.first.update!(adjustable_type: "Spree::Shipment") }
      it "returns #{boolean} if a #{type} attribute changes" do
        expect(subject).to be boolean
      end
    end

    context "deleting an adjustment" do
      before { order.all_adjustments.destroy_all }
      it "returns #{boolean} if a #{type} attribute changes" do
        expect(subject).to be boolean
      end
    end
  end
end

shared_examples "associated attribute changes - adjustments (update)" do |boolean, type|
  context "adjustment changes" do
    context "with an existing adjustment" do
      before { Spree::Adjustment.first.update!(label: "It's a new label") }
      it "returns #{boolean} if a #{type} attribute changes" do
        order.reload
        expect(subject).to be boolean
      end
    end
  end
end

shared_examples "associated attribute changes - line items" do |boolean, type|
  context "line item changes" do
    let(:line_item){ order.line_items.first }
    context "on quantitity" do
      before { line_item.update!(quantity: line_item.quantity + 1) }
      it "returns #{boolean} if a #{type} attribute changes" do
        order.reload
        expect(subject).to be boolean
      end
    end

    context "on variant id" do
      before { line_item.update!(variant_id: Spree::Variant.first.id) }
      it "returns #{boolean} if a #{type} attribute changes" do
        order.reload
        expect(subject).to be boolean
      end
    end
  end
end

shared_examples "associated attribute changes - bill address" do |boolean, type|
  context "bill address - a #{type}" do
    let(:bill_address) { Spree::Address.where(id: order.bill_address_id) }
    it "first name" do
      bill_address.update!(firstname: "Jane")
      order.reload
      expect(subject).to be boolean
    end

    it "last name" do
      bill_address.update!(lastname: "Jones")
      order.reload
      expect(subject).to be boolean
    end

    it "address (1)" do
      bill_address.update!(address1: "Rue du Fromage 66")
      order.reload
      expect(subject).to be boolean
    end

    it "address (2)" do
      bill_address.update!(address2: "South by Southwest")
      order.reload
      expect(subject).to be boolean
    end

    it "city" do
      bill_address.update!(city: "Antibes")
      order.reload
      expect(subject).to be boolean
    end

    it "zipcode" do
      bill_address.update!(zipcode: "04229")
      order.reload
      expect(subject).to be boolean
    end

    it "phone" do
      bill_address.update!(phone: "111-222-333")
      order.reload
      expect(subject).to be boolean
    end

    it "company" do
      bill_address.update!(company: "A Company Name")
      order.reload
      expect(subject).to be boolean
    end
  end
end

shared_examples "associated attribute changes - ship address" do |boolean, type|
  context "ship address - a #{type}" do
    let(:ship_address) { Spree::Address.where(id: order.ship_address_id) }
    it "first name" do
      ship_address.update!(firstname: "Jane")
      order.reload
      expect(subject).to be boolean
    end

    it "last name" do
      ship_address.update!(lastname: "Jones")
      order.reload
      expect(subject).to be boolean
    end

    it "address (1)" do
      ship_address.update!(address1: "Rue du Fromage 66")
      order.reload
      expect(subject).to be boolean
    end

    it "address (2)" do
      ship_address.update!(address2: "South by Southwest")
      order.reload
      expect(subject).to be boolean
    end

    it "city" do
      ship_address.update!(city: "Antibes")
      order.reload
      expect(subject).to be boolean
    end

    it "zipcode" do
      ship_address.update!(zipcode: "04229")
      order.reload
      expect(subject).to be boolean
    end

    it "phone" do
      ship_address.update!(phone: "111-222-333")
      order.reload
      expect(subject).to be boolean
    end

    it "company" do
      ship_address.update!(company: "A Company Name")
      order.reload
      expect(subject).to be boolean
    end
  end
end

shared_examples "associated attribute changes - payments" do |boolean, type|
  context "payment changes on" do
    let(:payment) { create(:payment, order_id: order.id) }
    context "amount" do
      before { payment.update!(amount: 222) }
      it "returns #{boolean} if a #{type} attribute changes" do
        order.reload
        expect(subject).to be boolean
      end
    end

    context "payment changes on" do
      let(:payment_method) { create(:payment_method) }
      context "payment method" do
        before { payment.update!(payment_method_id: payment_method.id) }
        it "returns #{boolean} if a #{type} attribute changes" do
          order.reload
          expect(subject).to be boolean
        end
      end
    end
  end
end

shared_examples "attribute changes - payment state" do |boolean, type|
  let(:payment) { order.payments.first }
  context "payment changes on" do
    context "state" do
      it "returns #{boolean} if a #{type} attribute changes" do
        expect {
          payment.started_processing
        }.to change { payment.state }.from("checkout").to("processing")
        order.reload
        expect(subject).to be boolean
      end
    end
  end
end

describe OrderInvoiceComparator do
  let!(:invoice){
    create(:invoice,
           order:,
           data: invoice_data_generator.serialize_for_invoice)
  }

  describe '#can_generate_new_invoice?' do
    # this passes 'order' as argument to the invoice comparator
    let(:order) { create(:completed_order_with_fees) }
    let!(:invoice_data_generator){ InvoiceDataGenerator.new(order) }
    let(:subject) {
      OrderInvoiceComparator.new(order).can_generate_new_invoice?
    }

    context "changes on the order object" do
      describe "detecting relevant" do
        it_behaves_like "attribute changes - order total", true, "relevant"
        it_behaves_like "attribute changes - tax total changes", true, "relevant", false
        it_behaves_like "attribute changes - tax total changes", true, "relevant", true
        it_behaves_like "attribute changes - shipping method", true, "relevant"
        it_behaves_like "associated attribute changes - adjustments (create)", true, "relevant"
        it_behaves_like "associated attribute changes - bill address", true, "relevant"
        it_behaves_like "associated attribute changes - ship address", true, "relevant"
        it_behaves_like "associated attribute changes - line items", true, "relevant"
        it_behaves_like "associated attribute changes - payments", true, "relevant"
      end

      describe "detecting non-relevant" do
        it_behaves_like "attribute changes - payment total", false, "relevant" do
          before { pending("a payment capture shouldn't trigger a new invoice - issue #11350") }
        end
        it_behaves_like "attribute changes - order state: cancelled", false, "non-relevant" do
          before { pending }
        end
        it_behaves_like "no attribute changes"
        it_behaves_like "attribute changes - special insctructions", false, "non-relevant"
        it_behaves_like "attribute changes - note", false, "non-relevant"
        it_behaves_like "associated attribute changes - adjustments (update)", false,
                        "non-relevant"
        it_behaves_like "attribute changes - payment state", false, "non-relevant"
      end
    end
  end

  describe '#can_update_latest_invoice?' do
    let!(:order) { create(:completed_order_with_fees) }
    let!(:invoice_data_generator){ InvoiceDataGenerator.new(order) }
    let(:subject) {
      OrderInvoiceComparator.new(order).can_update_latest_invoice?
    }

    context "changes on the order object" do
      describe "detecting relevant" do
        it_behaves_like "attribute changes - payment total", true, "relevant" do
          before { pending("a payment capture shouldn't trigger a new invoice - issue #11350") }
        end
        it_behaves_like "attribute changes - order state: cancelled", true, "relevant"
        it_behaves_like "attribute changes - special insctructions", true, "relevant"
        it_behaves_like "attribute changes - note", true, "relevant"
        it_behaves_like "associated attribute changes - adjustments (update)", true, "relevant"
        it_behaves_like "attribute changes - payment state", true, "relevant"
      end

      describe "detecting non-relevant" do
        it_behaves_like "attribute changes - order total", false, "non-relevant"
        it_behaves_like "attribute changes - tax total changes", false, "non-relevant", false
        it_behaves_like "attribute changes - tax total changes", false, "non-relevant", true
        it_behaves_like "attribute changes - shipping method", false, "non-relevant"
        it_behaves_like "no attribute changes"
        it_behaves_like "associated attribute changes - adjustments (create)", false,
                        "non-relevant"
        it_behaves_like "associated attribute changes - line items", false, "non-relevant"
        it_behaves_like "associated attribute changes - bill address", false, "non-relevant"
        it_behaves_like "associated attribute changes - ship address", false, "non-relevant"
        it_behaves_like "associated attribute changes - payments", false,
                        "non-relevant" do
          before { pending }
        end
      end
    end
  end
end
