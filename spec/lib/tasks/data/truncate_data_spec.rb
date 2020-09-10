# frozen_string_literal: true

require 'spec_helper'
require 'tasks/data/truncate_data'

describe TruncateData do
  describe '#call' do
    before do
      allow(Spree::ReturnAuthorization).to receive(:delete_all)
      allow(Rails.logger).to receive(:info)
    end

    context 'when months_to_keep is not specified' do
      it 'truncates order cycles closed earlier than 2 years ago' do
        order_cycle = create(
          :order_cycle, orders_open_at: 25.months.ago, orders_close_at: 25.months.ago + 1.day
        )
        create(:order, order_cycle: order_cycle)

        TruncateData.new.call

        expect(OrderCycle.all).to be_empty
      end
    end

    context 'when months_to_keep is nil' do
      it 'truncates order cycles closed earlier than 2 years ago' do
        order_cycle = create(
          :order_cycle, orders_open_at: 25.months.ago, orders_close_at: 25.months.ago + 1.day
        )
        create(:order, order_cycle: order_cycle)

        TruncateData.new(nil).call

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
          :order_cycle, orders_open_at: 1.month.ago, orders_close_at: 1.month.ago + 1.day
        )
        create(:order, order_cycle: recent_order_cycle)

        TruncateData.new(6).call

        expect(OrderCycle.all).to contain_exactly(recent_order_cycle)
      end
    end
  end
end
