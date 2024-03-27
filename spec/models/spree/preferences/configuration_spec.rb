# frozen_string_literal: true

require 'spec_helper'

class AppConfig < Spree::Preferences::Configuration
  preference :color, :string, default: :blue
end

describe Spree::Preferences::Configuration do
  let(:config) { AppConfig.new }

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
