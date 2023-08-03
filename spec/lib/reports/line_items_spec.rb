# frozen_string_literal: true

require 'spec_helper'

describe Reporting::LineItems do
  subject(:reports_line_items) { described_class.new(order_permissions, params) }

  # This object lets us add some test coverage despite the very deep coupling between the class
  # under test and the various objects it depends on. Other more common moking strategies where very
  # hard.
  class FakeOrderPermissions
    def initialize(line_items, orders_relation)
      @relations = Spree::LineItem.where(id: line_items.map(&:id))
      @orders_relation = orders_relation
    end

    def visible_line_items
      relations
    end

    def editable_line_items
      line_item = FactoryBot.create(:line_item)
      Spree::LineItem.where(id: line_item.id)
    end

    def visible_orders
      orders_relation
    end

    private

    attr_reader :relations, :orders_relation
  end

  describe '#list' do
    let!(:order) do
      create(
        :order,
        distributor: create(:enterprise),
        completed_at: 1.day.ago,
        shipments: [build(:shipment)]
      )
    end
    let!(:line_item1) { create(:line_item, order: order) }

    let(:orders_relation) { Spree::Order.where(id: order.id) }
    let(:order_permissions) { FakeOrderPermissions.new([line_item1], orders_relation) }
    let(:params) { {} }

    it 'returns masked data' do
      line_items = reports_line_items.list
      expect(line_items.first.order.email).to eq('HIDDEN')
    end

    context "when filtering by product" do
      subject(:line_items) { reports_line_items.list }

      let!(:line_item2) { create(:line_item, order: order) }
      let!(:line_item3) { create(:line_item, order: order) }
      let(:order_permissions) do
        FakeOrderPermissions.new([line_item1, line_item2, line_item3], orders_relation)
      end
      let(:params) { { variant_id_in: [line_item3.variant.id, line_item1.variant.id] } }

      context "with an empty array" do
        let(:params) { { variant_id_in: [""] } }

        it "does not filter" do
          expect(line_items).to include(line_item1, line_item2, line_item3)
        end
      end

      it "includes selected products" do
        expect(line_items).to include(line_item1, line_item3)
        expect(line_items).not_to include(line_item2)
      end
    end
  end
end
