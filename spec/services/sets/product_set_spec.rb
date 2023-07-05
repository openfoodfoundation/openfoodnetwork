# frozen_string_literal: true

require 'spec_helper'

describe Sets::ProductSet do
  describe '#save' do
    context 'when passing :collection_attributes' do
      let(:product_set) do
        described_class.new(collection_attributes: collection_hash)
      end

      context 'when the product does not exist yet' do
        let!(:stock_location) { create(:stock_location, backorderable_default: false) }
        let(:collection_hash) do
          {
            0 => {
              name: 'a product',
              price: 2.0,
              supplier_id: create(:enterprise).id,
              primary_taxon_id: create(:taxon).id,
              unit_description: 'description',
              variant_unit: 'items',
              variant_unit_name: 'bunches',
              shipping_category_id: create(:shipping_category).id
            }
          }
        end

        it 'does not create a new product' do
          product_set.save

          expect(Spree::Product.last).to be nil
        end
      end

      context 'when the product does exist' do
        context 'when a different variant_unit is passed' do
          let!(:product) do
            create(
              :simple_product,
              variant_unit: 'items',
              variant_unit_scale: nil,
              variant_unit_name: 'bunches',
              unit_value: nil,
              unit_description: 'some description'
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

          it 'updates the product' do
            product_set.save

            expect(product.reload.attributes).to include(
              'variant_unit' => 'weight'
            )
          end

          it 'does not add an error' do
            product_set.save
            expect(product_set.errors)
              .to be_empty
          end

          it 'returns true' do
            expect(product_set.save).to eq(true)
          end
        end

        context "when the product is in an order cycle" do
          let(:producer) { create(:enterprise) }
          let(:product) { create(:simple_product) }

          let(:distributor) { create(:distributor_enterprise) }
          let!(:order_cycle) {
            create(:simple_order_cycle, variants: [product.variants.first],
                                        coordinator: distributor,
                                        distributors: [distributor])
          }

          context 'and only the name changes' do
            let(:collection_hash) do
              { 0 => { id: product.id, name: "New season product" } }
            end

            it 'updates the product and keeps it in order cycles' do
              expect {
                product_set.save
                product.reload
              }.to change { product.name }.to("New season product").
                and change { order_cycle.distributed_variants.count }.by(0)

              expect(order_cycle.distributed_variants).to include product.variants.first
            end
          end

          context 'and a different supplier is passed' do
            let(:collection_hash) do
              { 0 => { id: product.id, supplier_id: producer.id } }
            end

            it 'updates the product and removes the product from order cycles' do
              expect {
                product_set.save
                product.reload
              }.to change { product.supplier }.to(producer).
                and change { order_cycle.distributed_variants.count }.by(-1)

              expect(order_cycle.distributed_variants).to_not include product.variants.first
            end
          end
        end

        context 'when attributes of the variants are passed' do
          let!(:product) { create(:simple_product) }
          let(:collection_hash) { { 0 => { id: product.id } } }

          context 'when :variants_attributes are passed' do
            let(:variants_attributes) { [{ sku: '123', id: product.variants.first.id.to_s }] }

            before { collection_hash[0][:variants_attributes] = variants_attributes }

            it 'updates the attributes of the variant' do
              product_set.save

              expect(product.reload.variants.first[:sku]).to eq variants_attributes.first[:sku]
            end

            context 'and when product attributes are also passed' do
              it 'updates product and variant attributes' do
                collection_hash[0][:sku] = "test_sku"

                product_set.save

                expect(product.reload.variants.first[:sku]).to eq variants_attributes.first[:sku]
                expect(product.reload.attributes).to include(
                  'sku' => "test_sku"
                )
              end
            end
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
              context 'and attributes provided are valid' do
                let(:master_attributes) do
                  attributes_for(:variant).merge(sku: '123')
                end

                it 'creates it with the specified attributes' do
                  number_of_variants = Spree::Variant.all.size
                  product_set.save
                  expect(Spree::Variant.last.sku).to eq('123')
                  expect(Spree::Variant.all.size).to eq number_of_variants + 1
                end
              end

              context 'and attributes provided are not valid' do
                let(:master_attributes) do
                  # unit_value nil makes the variant invalid
                  # on_hand with a value would make on_hand be updated and fail with exception
                  attributes_for(:variant).merge(unit_value: nil, on_hand: 1, sku: '321')
                end

                it 'does not create variant and notifies bugsnag still raising the exception' do
                  number_of_variants = Spree::Variant.all.size
                  expect(product_set.save).to eq(false)
                  expect(Spree::Variant.all.size).to eq number_of_variants
                  expect(Spree::Variant.last.sku).not_to eq('321')
                end
              end
            end
          end
        end
      end
    end
  end
end
