require 'spec_helper'

describe Openfoodnetwork::Application, 'configuration' do
  let(:config) { described_class.config }

  it "sets Spree::Stock::Splitter::Base as the only stock splitter" do
    expect(config.spree.stock_splitters).to eq [Spree::Stock::Splitter::Base]
  end
end
