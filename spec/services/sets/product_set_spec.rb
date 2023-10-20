# frozen_string_literal: true

require 'spec_helper'

describe Sets::ProductSet do
  describe '#save' do
    let(:product_set) do
      described_class.new(collection_attributes: collection_hash)
    end
    subject{ product_set.save }

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
      let(:product) { create(:simple_product, name: "product name") }

      context "with valid name" do
        let(:collection_hash) {
          { 0 => { id: product.id, name: "New season product" } }
        }

        it { is_expected.to eq true }
      end

      context "with invalid name" do
        let(:collection_hash) {
          { 0 => { id: product.id, name: "" } } # Product Name can't be blank
        }

        it { is_expected.to eq false }
      end

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

        it 'updates the product without error' do
          expect(product_set.save).to eq true

          expect(product.reload.attributes).to include(
            'variant_unit' => 'weight'
          )

          expect(product_set.errors).to be_empty
        end
      end

      context "when the product is in an order cycle" do
        let(:producer) { create(:enterprise) }

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
    end

    describe "updating a product's variants" do
      let(:product) { create(:simple_product) }
      let(:product_attributes) { {} }
      let(:variant_attributes) { { sku: "var_sku" } }
      let(:variants_attributes) { [{ **variant_attributes, id: product.variants.first.id.to_s }] }
      let(:collection_hash) {
        {
          0 => { id: product.id, **product_attributes, variants_attributes: }
        }
      }

      it "updates the variant" do
        expect {
          product_set.save
        }.to change { product.variants.first.sku }.to("var_sku")
      end

      shared_examples "nothing saved" do
        it "doesn't update product or variant" do
          expect {
            product_set.save
          }.to_not change { product.variants.first.sku }

          expect(product.reload.sku).to_not eq "prod_sku"
        end

        it 'updates the attributes of the variant' do
          expect {
            expect(product_set.save).to eq true
          }.to change { product.variants.first.sku }.to("123")

          expect(product_set.invalid.count).to eq 0
        end
      end

      context "variant has error" do
        let(:variant_attributes) { { sku: "var_sku", display_name: "A" * 256 } } # maximum length

        include_examples "nothing saved" do
          before { pending }
        end
      end

      context "when products attributes are also updated" do
        let(:product_attributes) {
          { sku: "prod_sku" }
        }

        it "updates product and variant" do
          expect {
            product_set.save
            product.reload
          }.to change { product.sku }.to("prod_sku")
            .and change { product.variants.first.sku }.to("var_sku")
        end

        context "variant has error" do
          let(:variant_attributes) { { sku: "var_sku", display_name: "A" * 256 } } # maximum length

          include_examples "nothing saved" do
            before { pending }
          end
        end

        context "product has error" do
          before { collection_hash[0][:name] = "" } # product.name can't be blank

          include_examples "nothing saved" do
            before { pending }
          end
        end
      end

      context "when multiple variants are updated" do
        let(:variant2) { create(:variant, product:) }
        let(:variants_attributes) {
          [
            { **variant_attributes, id: product.variants.first.id.to_s },
            { sku: "var_sku2", id: variant2.id.to_s },
          ]
        }

        it "updates each variant" do
          expect {
            product_set.save
            variant2.reload
          }.to change { product.variants.first.sku }.to("var_sku")
            .and change { variant2.sku }.to("var_sku2")
        end

        context "variant has error" do
          let(:variant_attributes) { { sku: "var_sku", display_name: "A" * 256 } } # maximum length

          include_examples "nothing saved" do
            before { pending }
            after { expect(variant2.reload.sku).to_not eq "var_sku2" }
          end
        end
      end
    end

    context 'when there are multiple products' do
      let!(:product_b) { create(:simple_product, name: "Bananas") }
      let!(:product_a) { create(:simple_product, name: "Apples") }

      let(:collection_hash) do
        {
          0 => {
            id: product_a.id,
            name: "Pommes",
          },
          1 => {
            id: product_b.id,
            name: "Bananes",
          },
        }
      end

      it 'updates the products' do
        product_set.save

        expect(product_a.reload.name).to eq "Pommes"
        expect(product_b.reload.name).to eq "Bananes"
      end

      it 'retains the order of products' do
        product_set.save

        expect(product_set.collection[0]).to eq product_a.reload
        expect(product_set.collection[1]).to eq product_b.reload
      end

      context 'first product has an error' do
        let(:collection_hash) do
          {
            0 => {
              id: product_a.id,
              name: "", # Product Name can't be blank
            },
            1 => {
              id: product_b.id,
              name: "Bananes",
            },
          }
        end

        it 'continues to update subsequent products' do
          product_set.save

          # Errors are logged on the model
          first_item = product_set.collection[0]
          expect(first_item.errors.full_messages.to_sentence).to eq "Product Name can't be blank"
          expect(first_item.name).to eq ""

          # Subsequent product was updated
          expect(product_b.reload.name).to eq "Bananes"
        end
      end
    end
  end
end
