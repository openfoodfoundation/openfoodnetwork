# frozen_string_literal: true

require 'spec_helper'
require 'open_food_network/enterprise_fee_calculator'

describe Api::ProductSerializer do
  include ShopWorkflow

  let!(:distributor) { create(:distributor_enterprise) }
  let!(:order_cycle) { create(:order_cycle, distributors: [distributor]) }
  let(:exchange) { order_cycle.exchanges.to_enterprises(distributor).outgoing.first }
  let!(:taxon) { create(:taxon) }
  let!(:property) { create(:property) }
  let!(:product) { create(:product, primary_taxon: taxon, properties: [property], price: 20.00) }
  let(:variant1) { create(:variant, product: product) }

  let(:serializer) {
    described_class.new(product,
                        variants: [variant1],
                        current_distributor: distributor,
                        current_order_cycle: order_cycle)
  }

  before do
    add_variant_to_order_cycle(exchange, variant1)
  end

  it "serializes various attributes" do
    expect(serializer.serializable_hash.keys).to eq [
      :id, :name, :meta_keywords, :group_buy, :notes, :description, :description_html,
      :properties_with_values, :variants, :primary_taxon, :image, :supplier
    ]
  end

  it "serializes product properties" do
    product_property = { id: property.id, name: property.presentation, value: nil }

    expect(serializer.serializable_hash[:properties_with_values]).to include product_property
  end
end
