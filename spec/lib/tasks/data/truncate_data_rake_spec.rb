# frozen_string_literal: true

require 'spec_helper'
require 'rake'

describe 'truncate_data.rake' do
  describe ':truncate' do
    context 'when months_to_keep is specified' do
      it 'truncates order cycles closed earlier than months_to_keep months ago' do
        Rake.application.rake_require 'tasks/data/truncate_data'
        Rake::Task.define_task(:environment)

        highline = instance_double(HighLine, agree: true)
        allow(HighLine).to receive(:new).and_return(highline)

        old_order_cycle = create(
          :order_cycle,
          orders_open_at: 7.months.ago,
          orders_close_at: 7.months.ago + 1.day,
        )
        create(:order, order_cycle: old_order_cycle)
        recent_order_cycle = create(
          :order_cycle,
          orders_open_at: 1.month.ago,
          orders_close_at: 1.month.ago + 1.day,
        )
        create(:order, order_cycle: recent_order_cycle)

        months_to_keep = 6
        Rake.application.invoke_task "ofn:data:truncate[#{months_to_keep}]"

        expect(OrderCycle.all).to contain_exactly(recent_order_cycle)
      end
    end
  end
end
