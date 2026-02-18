# frozen_string_literal: true

RSpec.describe CompleteOrdersWithBalanceQuery do
  subject(:result) { described_class.new(user).call }

  describe '#call' do
    let(:user) { order.user }
    let(:outstanding_balance) { instance_double(OutstandingBalanceQuery) }

    context 'when the user has complete orders' do
      let(:order) do
        create(:order, state: 'complete', total: 2.0, payment_total: 1.0, completed_at: 2.days.ago)
      end
      let!(:other_order) do
        create(
          :order,
          user:,
          state: 'complete',
          total: 2.0,
          payment_total: 1.0,
          completed_at: 1.day.ago
        )
      end

      it 'calls OutstandingBalanceQuery#call' do
        allow(OutstandingBalanceQuery).to receive(:new).and_return(outstanding_balance)
        allow(outstanding_balance).to receive(:call)

        result

        expect(outstanding_balance).to have_received(:call)
      end

      it 'returns complete orders including their balance' do
        order = result.first
        expect(order[:balance_value]).to eq(-1.0)
      end

      it 'sorts them by their completed_at with the most recent first' do
        expect(result.pluck(:id)).to eq([other_order.id, order.id])
      end
    end

    context 'when the user has no complete orders' do
      let(:order) { create(:order) }

      it 'calls OutstandingBalanceQuery' do
        allow(OutstandingBalanceQuery).to receive(:new).and_return(outstanding_balance)
        allow(outstanding_balance).to receive(:call)

        result

        expect(outstanding_balance).to have_received(:call)
      end

      it 'returns an empty array' do
        expect(result).to be_empty
      end
    end
  end
end
