# frozen_string_literal: true

require 'spec_helper'

describe Spree::ReturnAuthorization do
  let(:order) { create(:shipped_order) }
  let(:variant) { order.shipments.first.inventory_units.first.variant }
  let(:return_authorization) { Spree::ReturnAuthorization.new(order: order) }

  context "save" do
    it "should be invalid when order has no inventory units" do
      order.shipments.destroy_all
      return_authorization.save
      expect(return_authorization.errors[:order]).to eq ["has no shipped units"]
    end

    it "should generate RMA number" do
      expect(return_authorization).to receive(:generate_number)
      return_authorization.save
    end
  end

  context "add_variant" do
    context "on empty rma" do
      it "should associate inventory unit" do
        return_authorization.add_variant(variant.id, 1)
        expect(return_authorization.inventory_units.size).to eq 1
      end

      it "should associate inventory units as shipped" do
        return_authorization.add_variant(variant.id, 1)
        expect(return_authorization.inventory_units.where(state: 'shipped').size).to eq 1
      end

      it "should update order state" do
        expect(order).to receive(:authorize_return!)
        return_authorization.add_variant(variant.id, 1)
      end
    end

    context "on rma that already has inventory_units" do
      before do
        return_authorization.add_variant(variant.id, 1)
      end

      it "should not associate more inventory units than there are on the order" do
        return_authorization.add_variant(variant.id, 1)
        expect(return_authorization.inventory_units.size).to eq 1
      end

      it "should not update order state" do
        expect{ return_authorization.add_variant(variant.id, 1) }.to_not change{ order.state }
      end
    end
  end

  context "can_receive?" do
    it "should allow_receive when inventory units assigned" do
      allow(return_authorization).to receive_messages(inventory_units: [1, 2, 3])
      expect(return_authorization.can_receive?).to be_truthy
    end

    it "should not allow_receive with no inventory units" do
      allow(return_authorization).to receive_messages(inventory_units: [])
      expect(return_authorization.can_receive?).to be_falsy
    end
  end

  context "receive!" do
    let(:inventory_unit) { order.shipments.first.inventory_units.first }

    before do
      allow(return_authorization).to receive_messages(inventory_units: [inventory_unit],
                                                      amount: -20)
      allow(Spree::Adjustment).to receive(:create)
      allow(order).to receive(:update_order!)
    end

    it "should mark all inventory units are returned" do
      expect(inventory_unit).to receive(:return!)
      return_authorization.receive!
    end

    it "should add credit for specified amount" do
      return_authorization.amount = 20

      expect(Spree::Adjustment).to receive(:create).with(
        amount: -20,
        label: 'RMA credit',
        order: order,
        adjustable: order,
        originator: return_authorization
      )

      return_authorization.receive!
    end

    it "should update order state" do
      expect(order).to receive :update_order!
      return_authorization.receive!
    end
  end

  context "force_positive_amount" do
    it "should ensure the amount is always positive" do
      return_authorization.amount = -10
      return_authorization.send :force_positive_amount
      expect(return_authorization.amount).to eq 10
    end
  end

  context "after_save" do
    it "should run correct callbacks" do
      expect(return_authorization).to receive(:force_positive_amount)
      return_authorization.run_callbacks(:save)
    end
  end

  context "currency" do
    before { allow(order).to receive(:currency) { "ABC" } }
    it "returns the order currency" do
      expect(return_authorization.currency).to eq "ABC"
    end
  end

  context "display_amount" do
    it "returns a Spree::Money" do
      return_authorization.amount = 21.22
      expect(return_authorization.display_amount).to eq Spree::Money.new(21.22)
    end
  end

  context "returnable_inventory" do
    pending "should return inventory from shipped shipments" do
      expect(return_authorization.returnable_inventory).to eq [inventory_unit]
    end

    pending "should not return inventory from unshipped shipments" do
      expect(return_authorization.returnable_inventory).to eq []
    end
  end
end
