require 'spec_helper'
require 'rake'

describe 'order_cycles.rake' do
  describe ':remove_order_cycle' do
    before do
      Rake.application.rake_require 'tasks/order_cycles'
      Rake::Task.define_task(:environment)
      Rake::Task["ofn:remove_order_cycle"].reenable
    end

    context 'when the order cycle exists' do
      let!(:order_cycle) { create(:order_cycle) }

      it 'removes the specified order cycle' do
        expect {
          Rake.application.invoke_task "ofn:remove_order_cycle[#{order_cycle.id}]"
        }.to change(OrderCycle, :count).by(-1)
      end

      it 'removes the order cycle coordinator fees' do
        expect {
          Rake.application.invoke_task "ofn:remove_order_cycle[#{order_cycle.id}]"
        }.to change(CoordinatorFee, :count).by(-1)
      end
    end

    context 'when the order cycle does not exist' do
      it 'raises' do
        expect {
          Rake.application.invoke_task "ofn:remove_order_cycle[-1]"
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe ':remove_coordinated_order_cycles' do
    before do
      Rake.application.rake_require 'tasks/order_cycles'
      Rake::Task.define_task(:environment)
      Rake::Task["ofn:remove_coordinated_order_cycles"].reenable
    end

    it 'removes all order cycles of the specified coordinator' do
      order_cycle = create(:simple_order_cycle)
      coordinator = order_cycle.coordinator

      Rake.application.invoke_task "ofn:remove_coordinated_order_cycles[#{coordinator.id}]"

      expect(OrderCycle.where(coordinator_id: coordinator.id)).to be_empty
    end
  end
end
