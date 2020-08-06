# frozen_string_literal: true

require 'spec_helper'

describe Spree::Preferences::Store do
  before :each do
    @store = Spree::Preferences::StoreInstance.new
  end

  it "sets and gets a key" do
    @store.set :test, 1, :integer
    expect(@store.exist?(:test)).to be_truthy
    expect(@store.get(:test)).to eq 1
  end

  it "can set and get false values when cache return nil" do
    @store.set :test, false, :boolean
    expect(@store.get(:test)).to be_falsy
  end

  it "will return db value when cache is emtpy and cache the db value" do
    preference = Spree::Preference.where(key: 'test').first_or_initialize
    preference.value = '123'
    preference.value_type = 'string'
    preference.save

    Rails.cache.clear
    expect(@store.get(:test)).to eq '123'
    expect(Rails.cache.read(:test)).to eq '123'
  end

  it "should return and cache fallback value when supplied" do
    Rails.cache.clear
    expect(@store.get(:test, false)).to be_falsy
    expect(Rails.cache.read(:test)).to be_falsy
  end

  it "should return and cache fallback value when persistence is disabled (i.e. on bootstrap)" do
    Rails.cache.clear
    allow(@store).to receive_messages(should_persist?: false)
    expect(@store.get(:test, true)).to be_truthy
    expect(Rails.cache.read(:test)).to be_truthy
  end

  it "should return nil when key can't be found and fallback value is not supplied" do
    expect(@store.get(:random_key)).to be_nil
  end
end
