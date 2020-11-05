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
  let(:variant2) { create(:variant, product: product) }
  let(:master_variant) { product.master }

  let(:serializer) {
    described_class.new(product,
                        variants: [variant1, variant2],
                        master_variants: [master_variant],
                        current_distributor: distributor,
                        current_order_cycle: order_cycle)
  }

  before do
    add_variant_to_order_cycle(exchange, master_variant)
    add_variant_to_order_cycle(exchange, variant1)
    add_variant_to_order_cycle(exchange, variant2)
  end

  it "serializes various attributes" do
    expect(serializer.serializable_hash.keys).to eq serialized_attributes
  end

  it "serializes product properties" do
    product_property = { id: property.id, name: property.presentation, value: nil }

    expect(serializer.serializable_hash[:properties_with_values]).to include product_property
  end

  it "serializes taxons" do
    expect(serializer.serializable_hash[:taxons]).to eq [id: taxon.id]
  end

  describe "serializing price" do
    context "without enterprise fees" do
      it "returns the regular product price" do
        product_price = serializer.serializable_hash[:price]
        expect(product_price).to eq product.master.price
      end
    end

    context "with enterprise fees" do
      let(:simple_fee) { create(:enterprise_fee, enterprise: distributor, amount: 1000) }

      before { exchange.enterprise_fees << simple_fee }

      it "includes enterprise fees in the product price" do
        product_price = serializer.serializable_hash[:price]
        expect(product_price).to eq product.master.price + 1000
      end
    end

    context "when a specific calculator is used in fees" do
      let(:enterprise_fee_calculator) {
        OpenFoodNetwork::EnterpriseFeeCalculator.new distributor, order_cycle
      }
      let(:serializer) {
        described_class.new(product,
                            variants: [variant1, variant2],
                            master_variants: [master_variant],
                            current_distributor: distributor,
                            current_order_cycle: order_cycle,
                            enterprise_fee_calculator: enterprise_fee_calculator)
      }
      let!(:fee_with_calculator) {
        create(:enterprise_fee,
               amount: 20,
               fee_type: "admin",
               calculator: ::Calculator::FlatPercentPerItem.
                 new(preferred_flat_percent: 20))
      }

      before { exchange.enterprise_fees << fee_with_calculator }

      it "applies the correct calculated fee in the product price" do
        product_price = serializer.serializable_hash[:price]
        expect(product_price).to eq product.master.price + (product.master.price / 100 * 20)
      end
    end
  end

  private

  def serialized_attributes
    [
      :id, :name, :permalink, :meta_keywords, :group_buy, :notes, :description, :description_html,
      :properties_with_values, :price, :variants, :master, :primary_taxon, :taxons, :images,
      :supplier
    ]
  end
end
