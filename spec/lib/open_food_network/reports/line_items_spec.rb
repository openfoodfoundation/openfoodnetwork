require 'spec_helper'
require 'open_food_network/reports/line_items'

describe OpenFoodNetwork::Reports::LineItems do
  subject(:reports_line_items) { described_class.new(order_permissions, params) }

  # This object lets us add some test coverage despite the very deep coupling between the class
  # under test and the various objects it depends on. Other more common moking strategies where very
  # hard.
  class FakeOrderPermissions
    def initialize(line_item, orders_relation)
      @relation = Spree::LineItem.where(id: line_item.id)
      @orders_relation = orders_relation
    end

    def visible_line_items
      relation
    end

    def editable_line_items
      line_item = FactoryBot.create(:line_item)
      Spree::LineItem.where(id: line_item.id)
    end

    def visible_orders
      orders_relation
    end

    private

    attr_reader :relation, :orders_relation
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
    let!(:line_item) { create(:line_item, order: order) }

    let(:orders_relation) { Spree::Order.where(id: order.id) }
    let(:order_permissions) { FakeOrderPermissions.new(line_item, orders_relation) }
    let(:params) { {} }

    it 'returns masked data' do
      line_items = reports_line_items.list
      expect(line_items.first.order.email).to eq(I18n.t('admin.reports.hidden'))
    end
  end
end
