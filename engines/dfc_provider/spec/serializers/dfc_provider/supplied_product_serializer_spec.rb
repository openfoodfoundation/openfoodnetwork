# frozen_string_literal: true

require 'spec_helper'

describe DfcProvider::SuppliedProductSerializer do
  let!(:product) { create(:simple_product ) }
  let!(:variant) { product.variants.first }

  subject { described_class.new(variant) }

  describe '#id' do
    let(:supplied_product_id) {
      [
        'http://test.host/api/dfc_provider',
        'enterprises',
        product.supplier_id,
        'supplied_products',
        product.id
      ].join('/')
    }

    it 'returns the expected value' do
      expect(subject.id).to eq(supplied_product_id)
    end
  end

  describe '#unit' do
    it 'returns the rdfs label value' do
      expect(subject.unit).to eq(
        '@id' => '/unit/piece',
        'rdfs:label' => 'piece'
      )
    end
  end
end
