require 'spec_helper'

describe NullShippingMethod do
  describe '#name' do
    it 'returns nil' do
      expect(described_class.new.name).to eq(nil)
    end
  end

  describe '#require_ship_address' do
    it 'returns nil' do
      expect(described_class.new.require_ship_address).to eq(nil)
    end
  end
end
