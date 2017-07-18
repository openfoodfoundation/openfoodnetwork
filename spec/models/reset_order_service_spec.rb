require 'spec_helper'

describe ResetOrderService do
  let(:current_distributor) { double(:distributor) }
  let(:current_token) { double(:current_token) }
  let(:current_order) { double(:current_order) }
  let(:tokenized_permission) { double(:tokenized_permission, save!: true) }
  let(:new_order) do
    double(
      :new_order,
      distributor: current_distributor,
      token: current_token,
      set_distributor!: true,
      tokenized_permission: tokenized_permission,
    )
  end
  let(:session) { double(:session) }
  let(:controller) { double(:controller, current_order: new_order, session: session) }
  let(:reset_order_service) { described_class.new(controller) }

  before do
    allow(current_order).to receive(:tokenized_permission).and_return(tokenized_permission)
    allow(tokenized_permission).to receive(:token=)
    allow(session).to receive(:[]=).with(:order_id, nil)
    allow(session).to receive(:[]=).with(:access_token, current_token)
  end

  describe '#call' do
    it 'creates a new order' do
      reset_order_service.call
      expect(controller).to have_received(:current_order).once.with(true)
    end

    it 'empties the order_id of the session' do
      reset_order_service.call
      expect(session).to have_received(:[]=).with(:order_id, nil)
    end

    it 'resets the @current_order var' do
      reset_order_service.call
      expect(controller.instance_variable_get(:@current_order)).to be_nil
    end

    it 'sets the new order\'s distributor to the same as the old order' do
      reset_order_service.call

      expect(new_order)
        .to have_received(:set_distributor!)
        .with(current_distributor)
    end

    it 'sets the token of the tokenized permissions' do
      reset_order_service.call

      expect(current_order.tokenized_permission)
        .to have_received(:token=).with(current_token)
    end

    it 'persists the tokenized permissions' do
      reset_order_service.call
      expect(tokenized_permission).to have_received(:save!)
    end

    it 'sets the access_token of the session' do
      reset_order_service.call
      expect(session).to have_received(:[]=).with(:access_token, current_token)
    end
  end
end
