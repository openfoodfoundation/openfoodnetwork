# frozen_string_literal: true

require 'spec_helper'

describe Spree::OrderInventory do
  let(:order) { create :completed_order_with_totals }
  let(:line_item) { order.line_items.first }
  subject { described_class.new(order) }

  it 'inventory_units_for should return array of units for a given variant' do
    units = subject.inventory_units_for(line_item.variant)
    expect(units.map(&:variant_id)).to eq [line_item.variant.id]
  end

  context "when order is missing inventory units" do
    before do
      line_item.update_column(:quantity, 2)
    end

    it 'should be a messed up order' do
      expect(order.shipments.first.inventory_units_for(line_item.variant).size).to eq 1
      expect(line_item.reload.quantity).to eq 2
    end

    it 'should increase the number of inventory units' do
      subject.verify(line_item)
      expect(order.reload.shipments.first.inventory_units_for(line_item.variant).size).to eq 2
    end
  end

  context "#add_to_shipment" do
    let(:shipment) { order.shipments.first }
    let(:variant) { create :variant }

    context "order is not completed" do
      before { order.stub completed?: false }

      it "doesn't unstock items" do
        shipment.stock_location.should_not_receive(:unstock)
        expect(subject.send(:add_to_shipment, shipment, variant, 5)).to eq 5
      end
    end

    it 'should create inventory_units in the necessary states' do
      shipment.stock_location.should_receive(:fill_status).with(variant, 5).and_return([3, 2])

      expect(subject.send(:add_to_shipment, shipment, variant, 5)).to eq 5

      units = shipment.inventory_units.group_by &:variant_id
      units = units[variant.id].group_by &:state
      expect(units['backordered'].size).to eq 2
      expect(units['on_hand'].size).to eq 3
    end

    it 'should create stock_movement' do
      expect(subject.send(:add_to_shipment, shipment, variant, 5)).to eq 5

      stock_item = shipment.stock_location.stock_item(variant)
      movement = stock_item.stock_movements.last
      expect(movement.quantity).to eq(-5)
    end
  end

  context 'when order has too many inventory units' do
    before do
      line_item.quantity = 3
      line_item.save!

      line_item.update_column(:quantity, 2)
      order.reload
    end

    it 'should be a messed up order' do
      expect(order.shipments.first.inventory_units_for(line_item.variant).size).to eq 3
      expect(line_item.quantity).to eq 2
    end

    it 'should decrease the number of inventory units' do
      subject.verify(line_item)
      expect(order.reload.shipments.first.inventory_units_for(line_item.variant).size).to eq 2
    end

    context '#remove_from_shipment' do
      let(:shipment) { order.shipments.first }
      let(:variant) { order.line_items.first.variant }

      context "order is not completed" do
        before { order.stub completed?: false }

        it "doesn't restock items" do
          shipment.stock_location.should_not_receive(:restock)
          expect(subject.send(:remove_from_shipment, shipment, variant, 1)).to eq 1
        end
      end

      it 'should create stock_movement' do
        expect(subject.send(:remove_from_shipment, shipment, variant, 1)).to eq 1

        stock_item = shipment.stock_location.stock_item(variant)
        movement = stock_item.stock_movements.last
        expect(movement.quantity).to eq 1
      end

      it 'should destroy backordered units first' do
        shipment.stub(inventory_units_for: [build(:inventory_unit, variant_id: variant.id, state: 'backordered'),
                                            build(:inventory_unit, variant_id: variant.id, state: 'on_hand'),
                                            build(:inventory_unit, variant_id: variant.id, state: 'backordered')])

        shipment.inventory_units_for[0].should_receive(:destroy)
        shipment.inventory_units_for[1].should_not_receive(:destroy)
        shipment.inventory_units_for[2].should_receive(:destroy)

        expect(subject.send(:remove_from_shipment, shipment, variant, 2)).to eq 2
      end

      it 'should destroy unshipped units first' do
        shipment.stub(inventory_units_for: [build(:inventory_unit, variant_id: variant.id, state: 'shipped'),
                                            build(:inventory_unit, variant_id: variant.id, state: 'on_hand')] )

        shipment.inventory_units_for[0].should_not_receive(:destroy)
        shipment.inventory_units_for[1].should_receive(:destroy)

        expect(subject.send(:remove_from_shipment, shipment, variant, 1)).to eq 1
      end

      it 'only attempts to destroy as many units as are eligible, and return amount destroyed' do
        shipment.stub(inventory_units_for: [build(:inventory_unit, variant_id: variant.id, state: 'shipped'),
                                            build(:inventory_unit, variant_id: variant.id, state: 'on_hand')] )

        shipment.inventory_units_for[0].should_not_receive(:destroy)
        shipment.inventory_units_for[1].should_receive(:destroy)

        expect(subject.send(:remove_from_shipment, shipment, variant, 1)).to eq 1
      end

      it 'should destroy self if not inventory units remain' do
        shipment.inventory_units.stub(count: 0)
        shipment.should_receive(:destroy)

        expect(subject.send(:remove_from_shipment, shipment, variant, 1)).to eq 1
      end
    end
  end
end
