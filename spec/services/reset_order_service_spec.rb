require 'spec_helper'

describe ResetOrderService do
  let(:current_token) { double(:current_token) }
  let(:current_distributor) { double(:distributor) }
  let(:current_order) do
    double(
      :current_order,
      token: current_token,
      distributor: current_distributor
    )
  end
  let(:tokenized_permission) { double(:tokenized_permission, save!: true) }
  let(:new_order) do
    double(
      :new_order,
      set_distributor!: true,
      tokenized_permission: tokenized_permission,
    )
  end
  let(:controller) do
    double(
      :controller,
      current_order: new_order,
      expire_current_order: true
    )
  end
  let(:reset_order_service) { described_class.new(controller, current_order) }

  before do
    allow(new_order)
      .to receive(:tokenized_permission)
      .and_return(tokenized_permission)

    allow(tokenized_permission).to receive(:token=)
  end

  describe '#call' do
    it 'creates a new order' do
      reset_order_service.call
      expect(controller).to have_received(:current_order).once.with(true)
    end

    it 'sets the new order\'s distributor to the same as the old order' do
      reset_order_service.call

      expect(new_order)
        .to have_received(:set_distributor!)
        .with(current_distributor)
    end

    it 'sets the token of the tokenized permissions' do
      reset_order_service.call

      expect(new_order.tokenized_permission)
        .to have_received(:token=).with(current_token)
    end

    it 'persists the tokenized permissions' do
      reset_order_service.call
      expect(tokenized_permission).to have_received(:save!)
    end
  end
end
