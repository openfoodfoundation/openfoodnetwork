require 'spec_helper'

describe Spree::ProductSet do
  describe '#save' do
    context 'when passing :collection_attributes' do
      let(:product_set) do
        described_class.new(collection_attributes: collection_hash)
      end

      context 'when the product does not exist yet' do
        let(:collection_hash) do
          {
            0 => {
              product_id: 11,
              name: 'a product',
              price: 2.0,
              supplier_id: create(:enterprise).id,
              primary_taxon_id: create(:taxon).id,
              unit_description: 'description',
              variant_unit: 'items',
              variant_unit_name: 'bunches'
            }
          }
        end

        it 'creates it with the specified attributes' do
          product_set.save

          expect(Spree::Product.last.attributes)
            .to include('name' => 'a product')
        end
      end

      context 'when the product does exist' do
        let!(:product) do
          create(
            :simple_product,
            variant_unit: 'items',
            variant_unit_scale: nil,
            variant_unit_name: 'bunches'
          )
        end

        let(:collection_hash) do
          {
            0 => {
              id: product.id,
              variant_unit: 'weight',
              variant_unit_scale: 1
            }
          }
        end

        it 'updates all the specified product attributes' do
          product_set.save

          expect(product.reload.attributes).to include(
            'variant_unit' => 'weight',
            'variant_unit_scale' => 1
          )
        end

        context 'when :master_attributes is passed' do
          let(:master_attributes) { { sku: '123' } }

          before do
            collection_hash[0][:master_attributes] = master_attributes
          end

          context 'and the variant does exist' do
            let!(:variant) { create(:variant, product: product) }

            before { master_attributes[:id] = variant.id }

            it 'updates the attributes of the master variant' do
              product_set.save
              expect(variant.reload.sku).to eq('123')
            end
          end

          context 'and the variant does not exist' do
            let(:master_attributes) do
              attributes_for(:variant).merge(sku: '123')
            end

            it 'creates it with the specified attributes' do
              product_set.save
              expect(Spree::Variant.last.sku).to eq('123')
            end
          end
        end
      end
    end
  end
end
