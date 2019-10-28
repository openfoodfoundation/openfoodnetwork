require 'spec_helper'
require 'rake'

describe 'enterprises.rake' do
  describe ':truncate_distributor' do
    let!(:distributor) { create(:enterprise) }
    let!(:order) { create(:order, distributor: distributor) }

    before do
      Rake.application.rake_require 'tasks/enterprises'
      Rake::Task.define_task(:environment)
      Rake::Task["ofn:truncate_distributor"].reenable
    end

    it 'destroys all orders of the specified distributor' do
      Rake.application.invoke_task "ofn:truncate_distributor[#{distributor.id}]"

      expect(Spree::Order.where(distributor_id: order.distributor_id)).to be_empty
    end

    it 'deletes all their inventory units' do
      inventory_unit = create(:inventory_unit, order: order)

      Rake.application.invoke_task "ofn:truncate_distributor[#{distributor.id}]"

      expect(Spree::InventoryUnit.where(order_id: order.id)).to be_empty
    end

    it 'destroys their line items' do
      create(:line_item, order: order)

      Rake.application.invoke_task "ofn:truncate_distributor[#{distributor.id}]"

      expect(Spree::LineItem.where(order_id: order.id)).to be_empty
    end

    it 'destroys their proxy orders' do
      create(:proxy_order, order: order)

      Rake.application.invoke_task "ofn:truncate_distributor[#{distributor.id}]"

      expect(ProxyOrder.where(order_id: order.id)).to be_empty
    end
  end
end
