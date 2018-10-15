require 'spec_helper'

describe Spree::Order do
  describe 'event :restart_checkout' do
    context 'when the order is not complete' do
      let(:order) { create(:order) }

      before { allow(order).to receive(:completed?) { false } }

      it 'does transition to cart state' do
        expect(order.state).to eq('cart')
      end
    end

    context 'when the order is complete' do
      let(:order) { create(:order) }

      before { allow(order).to receive(:completed?) { true } }

      it 'raises' do
        expect { order.restart_checkout! }
          .to raise_error(
            StateMachine::InvalidTransition,
            /Cannot transition state via :restart_checkout/
          )
      end
    end
  end
end
