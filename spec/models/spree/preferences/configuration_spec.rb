# frozen_string_literal: true

RSpec.describe Spree::Preferences::Configuration do
  let(:config) do
    Class.new(Spree::Preferences::Configuration) do
      preference :color, :string, default: :blue
    end.new
  end

  it "has named methods to access preferences" do
    config.color = 'orange'
    expect(config.color).to eq 'orange'
  end

  it "uses [ ] to access preferences" do
    config[:color] = 'red'
    expect(config[:color]).to eq 'red'
  end

  it "uses set/get to access preferences" do
    config.set :color, 'green'
    expect(config.get(:color)).to eq 'green'
  end
end
