require 'spec_helper'

describe Delivery do
  let(:order) { build(:order) }
  let(:delivery) { described_class.new(order) }

  describe '#ship_address_on_clear' do
    it { expect(delivery.ship_address_on_clear).to eq(order.ship_address) }
  end
end
