require 'spec_helper'

describe Pickup do
  let(:order) { build(:order) }
  let(:pickup) { described_class.new(order) }

  describe '#ship_address_on_clear' do
    it { expect(pickup.ship_address_on_clear).to eq(Spree::Address.default) }
  end
end
