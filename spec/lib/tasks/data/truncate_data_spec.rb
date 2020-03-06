require 'spec_helper'
require 'tasks/data/truncate_data'

describe TruncateData do
  describe '#call' do
    before do
      allow(Spree::ReturnAuthorization).to receive(:delete_all)
      allow(Spree::StateChange).to receive(:delete_all)
      allow(Spree::LogEntry).to receive(:delete_all)
    end

    context 'when months_to_keep is not specified' do
      it 'truncates order cycles closed earlier than 3 months ago' do
        order_cycle = create(
          :order_cycle, orders_open_at: 4.months.ago, orders_close_at: 4.months.ago + 1.day
        )
        create(:order, order_cycle: order_cycle)

        TruncateData.new.call

        expect(OrderCycle.all).to be_empty
      end
    end

    context 'when months_to_keep is nil' do
      it 'truncates order cycles closed earlier than 3 months ago' do
        order_cycle = create(
          :order_cycle, orders_open_at: 4.months.ago, orders_close_at: 4.months.ago + 1.day
        )
        create(:order, order_cycle: order_cycle)

        TruncateData.new(months_to_keep: nil).call

        expect(OrderCycle.all).to be_empty
      end
    end

    context 'when months_to_keep is specified' do
      it 'truncates order cycles closed earlier than months_to_keep months ago' do
        old_order_cycle = create(
          :order_cycle, orders_open_at: 7.months.ago, orders_close_at: 7.months.ago + 1.day
        )
        create(:order, order_cycle: old_order_cycle)
        recent_order_cycle = create(
          :order_cycle, orders_open_at: 1.months.ago, orders_close_at: 1.months.ago + 1.day
        )
        create(:order, order_cycle: recent_order_cycle)

        TruncateData.new(months_to_keep: 6).call

        expect(OrderCycle.all).to contain_exactly(recent_order_cycle)
      end
    end
  end
end

