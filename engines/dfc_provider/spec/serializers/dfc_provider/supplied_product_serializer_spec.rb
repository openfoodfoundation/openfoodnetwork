# frozen_string_literal: true

require 'spec_helper'

describe DfcProvider::SuppliedProductSerializer do
  let!(:product) { create(:simple_product ) }
  let!(:variant) { product.variants.first }

  subject { described_class.new(variant) }

  describe '#id' do
    it 'returns the expected value' do
      expect(subject.id).to eq(
        DfcProvider::Engine.routes.url_helpers.api_dfc_provider_enterprise_supplied_product_url(
          enterprise_id: product.supplier_id,
          id: variant.id,
          host: 'http://test.host'
        )
      )
    end
  end

  describe '#unit' do
    it 'returns the rdfs label value' do
      expect(subject.unit).to eq(
        {
          '@id' => '/unit/piece',
          'rdfs:label' => 'piece'
        }
      )
    end
  end
end
