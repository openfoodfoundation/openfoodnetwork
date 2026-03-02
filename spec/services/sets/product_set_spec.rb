# frozen_string_literal: true

RSpec.describe Sets::ProductSet do
  describe '#save' do
    let(:product_set) do
      described_class.new(collection_attributes: collection_hash)
    end
    subject{ product_set.save }

    context 'when the product does not exist yet' do
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

        it "returns true and counts results" do
          is_expected.to eq true
          expect(product_set.saved_count).to eq 1
        end
      end

      context "with invalid name" do
        let(:collection_hash) {
          { 0 => { id: product.id, name: "" } } # Product Name can't be blank
        }

        it "returns false and counts results" do
          is_expected.to eq false
          expect(product_set.saved_count).to eq 0
        end
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
        let(:variant) { product.variants.first }

        let(:collection_hash) do
          {
            0 => {
              id: product.id,
              variants_attributes: [{
                id: variant.id.to_s,
                variant_unit: 'weight',
                variant_unit_scale: 1
              }]
            }
          }
        end

        it 'updates the product without error' do
          expect(product_set.save).to eq true
          # updating variant doesn't increment saved_count
          # expect(product_set.saved_count).to eq 1

          expect(variant.reload.attributes).to include(
            'variant_unit' => 'weight'
          )

          expect(product_set.errors).to be_empty
        end
      end

      context "when the product is in an order cycle" do
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
      end

      context "when product attributes are not changed" do
        let(:collection_hash) {
          { 0 => { id: product.id, name: product.name } }
        }

        it 'returns true' do
          is_expected.to eq true
        end

        it 'does not increase saved_count' do
          subject
          expect(product_set.saved_count).to eq 0
        end

        it 'does not update any product by calling save' do
          expect_any_instance_of(Spree::Product).not_to receive(:save)

          subject
        end
      end
    end

    describe "updating a product's variants" do
      let(:product) { create(:simple_product, supplier_id: create(:supplier_enterprise).id) }
      let(:variant) { product.variants.first }
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
          variant.reload
        }.to change { variant.sku }.to("var_sku")

        pending
        expect(product_set.saved_count).to eq 1
      end

      shared_examples "nothing saved" do
        it "doesn't update product" do
          expect {
            product_set.save
            product.reload
          }.not_to change { product.sku }

          expect(product_set.saved_count).to be_zero
          expect(product_set.invalid.count).to be_positive
        end

        it "doesn't update variant" do
          expect {
            product_set.save
            variant.reload
          }.not_to change { variant.sku }
        end

        it 'assigns the in-memory attributes of the variant' do
          pending
          expect {
            product_set.save
          }.to change { variant.sku }.to("123")
        end
      end

      context "variant has error" do
        let(:variant_attributes) { { sku: "var_sku", display_name: "A" * 256 } } # maximum length

        include_examples "nothing saved"
      end

      context "when attributes are not changed" do
        let(:variant_attributes) { { sku: variant.sku } }

        before { variant }

        it 'updates product by calling save' do
          expect_any_instance_of(Spree::Variant).not_to receive(:save)

          subject
        end

        it 'does not increase saved_count' do
          subject
          expect(product_set.saved_count).to eq 0
        end
      end

      context "when the variant is in an order cycle" do
        let(:distributor) { create(:distributor_enterprise) }
        let!(:order_cycle) {
          create(:simple_order_cycle, variants: [variant],
                                      coordinator: distributor,
                                      distributors: [distributor])
        }
        let(:variant_attributes) { { display_name: "New season variant" } }

        it 'updates the variant and keeps it in order cycles' do
          expect {
            product_set.save
            variant.reload
          }.to change { variant.display_name }.to("New season variant").
            and change { order_cycle.distributed_variants.count }.by(0)

          expect(order_cycle.distributed_variants).to include variant
        end

        context 'when supplier is updated' do
          let(:producer) { create(:supplier_enterprise) }
          let(:variant_attributes) { { supplier_id: producer.id } }

          it 'updates the variant and removes the variant from order cycles' do
            expect {
              product_set.save
              variant.reload
            }.to change { variant.supplier }.to(producer).
              and change { order_cycle.distributed_variants.count }.by(-1)

            expect(order_cycle.distributed_variants).not_to include variant
          end
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

          expect(product_set.saved_count).to eq 1
        end

        xcontext "variant has error" do
          let(:variant_attributes) { { sku: "var_sku", display_name: "A" * 256 } } # maximum length

          include_examples "nothing saved"
        end

        context "product has error" do
          before { collection_hash[0][:name] = "" } # product.name can't be blank

          include_examples "nothing saved"
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

        xcontext "variant has error" do
          let(:variant_attributes) { { sku: "var_sku", display_name: "A" * 256 } } # maximum length

          include_examples "nothing saved" do
            after { expect(variant2.reload.sku).not_to eq "var_sku2" }
          end
        end
      end

      context "new variant" do
        let(:variants_attributes) {
          [
            { id: product.variants.first.id.to_s }, # default variant unchanged
            # omit ID for new variant
            {
              sku: "new sku", price: "5.00", unit_value: "5", variant_unit: "weight",
              variant_unit_scale: 1, supplier_id: supplier.id, primary_taxon_id: create(:taxon).id
            },
          ]
        }
        let(:supplier) { create(:supplier_enterprise) }

        it "creates new variant" do
          expect {
            product_set.save
            expect(product_set.errors).to be_empty
          }.to change { product.variants.count }.by(1)

          variant = product.variants.last
          expect(variant.sku).to eq "new sku"
          expect(variant.price).to eq 5.00
          expect(variant.unit_value).to eq 5
          expect(variant.variant_unit).to eq "weight"
          expect(variant.variant_unit_scale).to eq 1
        end

        context "variant has error" do
          let(:variants_attributes) {
            [
              { id: product.variants.first.id.to_s }, # default variant unchanged
              # price missing, unit_value should be number
              { sku: "new sku", unit_value: "blah", supplier_id: supplier.id },
            ]
          }

          include_examples "nothing saved"

          it "logs variant errors" do
            product_set.save
            expect(product_set.errors.full_messages).to include(
              "Variant price is not a number",
              "Variant price can't be blank",
              "Variant unit value is not a number"
            )
          end
        end
      end
    end

    context 'when there are multiple products' do
      let(:product_c) { create(:simple_product, name: "Carrots") }
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
          2 => {
            id: product_c.id,
            name: "Carrots",
          },
        }
      end

      it 'updates the products' do
        expect(product_set.save).to eq true
        expect(product_set.saved_count).to eq 2 # only two were changed

        expect(product_a.reload.name).to eq "Pommes"
        expect(product_b.reload.name).to eq "Bananes"
        expect(product_c.reload.name).to eq "Carrots" # no change
      end

      it 'retains the order of products' do
        product_set.save

        # even though the first product is now alphabetically last
        expect(product_set.collection[0]).to eq product_a.reload
        expect(product_set.collection[1]).to eq product_b.reload
        expect(product_set.collection[2]).to eq product_c.reload
      end

      context 'first product has an error' do
        before { collection_hash[0][:name] = "" } # product.name can't be blank

        it 'continues to update subsequent products' do
          product_set.save
          expect(product_set.saved_count).to eq 1

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
