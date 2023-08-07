# frozen_string_literal: true

require 'spec_helper'

describe Api::EnterpriseShopfrontSerializer do
  let!(:hub) { create(:distributor_enterprise, with_payment_and_shipping: true) }
  let!(:producer) { create(:supplier_enterprise) }
  let!(:producer_hidden) { create(:supplier_enterprise_hidden) }
  let!(:relationship) { create(:enterprise_relationship, parent: producer, child: hub) }
  let!(:relationship2) { create(:enterprise_relationship, parent: producer_hidden, child: hub) }

  let!(:taxon1) { create(:taxon, name: 'Meat') }
  let!(:taxon2) { create(:taxon, name: 'Veg') }
  let!(:product) {
    create(:product, supplier: producer, primary_taxon: taxon1 )
  }
  let!(:product2) {
    create(:product, supplier: producer_hidden, primary_taxon: taxon2 )
  }

  let(:close_time) { 2.days.from_now }
  let!(:oc) { create(:simple_order_cycle, orders_close_at: close_time, distributors: [hub]) }

  let!(:ex) {
    create(:exchange, order_cycle: oc, incoming: false,
                      sender: producer, receiver: hub)
  }
  let!(:ex2) {
    create(:exchange, order_cycle: oc, incoming: false,
                      sender: producer_hidden, receiver: hub)
  }

  let(:serializer) { Api::EnterpriseShopfrontSerializer.new hub }

  before do
    ex.variants << product.variants.first
  end

  it "serializes next order cycle close time" do
    expect(serializer.serializable_hash[:orders_close_at].round).to match oc.orders_close_at.round
  end

  it "serializes shipping method types" do
    expect(serializer.serializable_hash[:pickup]).to eq false
    expect(serializer.serializable_hash[:delivery]).to eq true
  end

  it "serializes an array of hubs" do
    expect(serializer.serializable_hash[:hubs]).to be_a ActiveModel::ArraySerializer
    expect(serializer.serializable_hash[:hubs].to_json).to match hub.name
  end

  context 'when hub is marked as hidden' do
    before { hub.update_column(:visible, 'hidden') }

    it 'serializes an array of public hubs' do
      expect(serializer.serializable_hash[:hubs]).to be_a ActiveModel::ArraySerializer
      expect(serializer.serializable_hash[:hubs].to_json).not_to match hub.name
    end
  end

  it "serializes an array of producers that are public or linked by links" do
    expect(serializer.serializable_hash[:producers]).to be_a ActiveModel::ArraySerializer
    expect(serializer.serializable_hash[:producers].to_json).to match producer.name
  end

  it "serializes taxons" do
    expect(serializer.serializable_hash[:taxons]).to be_a ActiveModel::ArraySerializer
    expect(serializer.serializable_hash[:taxons].to_json).to match 'Meat'
  end
end
