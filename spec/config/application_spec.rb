require 'spec_helper'

describe Openfoodnetwork::Application, 'configuration' do
  let(:config) { described_class.config }

  it "sets OrderManagement::Stock::BasicSplitter as the only stock splitter" do
    expect(config.spree.stock_splitters).to eq [OrderManagement::Stock::BasicSplitter]
  end
end
