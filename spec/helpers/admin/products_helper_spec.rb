# frozen_string_literal: true

RSpec.describe Admin::ProductsHelper do
  describe '#product_carousel_images_data' do
    context 'when product has images' do
      it 'returns normalized image data for each product image' do
        product = create(:product_with_image, images_count: 2)
        product.images.update_all(alt: 'Front of pack')

        data = helper.product_carousel_images_data(product)

        expect(data).not_to be_empty
        expect(data.first[:url]).to eq(product.images.first.url(:large))
        expect(data.first[:alt]).to eq('Front of pack')
        expect(data.first[:caption]).to eq("#{product.name} - 1")
        expect(data.second[:url]).to eq(product.images.second.url(:large))
        expect(data.second[:alt]).to eq('Front of pack')
        expect(data.second[:caption]).to eq("#{product.name} - 2")
      end

      it 'falls back to the product name when the image has no alt text' do
        product = create(:product_with_image)
        data = helper.product_carousel_images_data(product)

        expect(data.first[:alt]).to eq(product.name)
        expect(data.first[:caption]).to be_nil
      end
    end

    context 'when product has no images' do
      let(:product) { create(:product) }

      it 'returns a default fallback image entry' do
        data = helper.product_carousel_images_data(product)

        expect(data).to eq([
                             {
                               url: Spree::Image.default_image_url(:large),
                               alt: product.name,
                               caption: nil
                             }
                           ])
      end
    end
  end

  describe '#unit_value_with_description' do
    let(:variant) {
      create(:variant, variant_unit_scale: 1000.0, unit_value: 2000.0, unit_description: 'kg')
    }

    context 'when unit_value and unit_description are present' do
      it 'returns the scaled unit value with the description' do
        expect(helper.unit_value_with_description(variant)).to eq('2 kg')
      end
    end

    context 'when unit_value is nil' do
      before { variant.update_column(:unit_value, nil) }

      it 'returns the description' do
        expect(helper.unit_value_with_description(variant)).to eq('kg')
      end
    end

    context 'when unit_description is nil' do
      before { variant.update_column(:unit_description, nil) }

      it 'returns only the scaled unit value' do
        expect(helper.unit_value_with_description(variant)).to eq('2')
      end
    end

    context 'when variant_unit_scale is nil' do
      before { variant.update_column(:variant_unit_scale, nil) }

      it 'uses default scale of 1 and returns the unscaled unit value with the description' do
        expect(helper.unit_value_with_description(variant)).to eq('2000 kg')
      end
    end

    context 'when both unit_value and unit_description are nil' do
      before { variant.update_columns(unit_description: nil, unit_value: nil) }

      it 'returns empty string' do
        expect(helper.unit_value_with_description(variant)).to eq('')
      end
    end
  end

  describe '#prepare_new_variant' do
    let(:zone) { create(:zone_with_member) }
    let(:taxon) { create(:taxon) }
    let(:supplier) { create(:supplier_enterprise) }
    let(:product) {
      create(:taxed_product, zone:, price: 12.54, tax_rate_amount: 0,
                             included_in_price: true)
    }

    before do
      product.variants.last.update!(
        primary_taxon: taxon,
        enterprise: supplier,
        variant_unit: "weight",
        variant_unit_scale: 1000.0,
        unit_value: 1000.0,
        price: 9.99,
      )
    end

    it 'copies tax category from the last variant' do
      expect(helper.prepare_new_variant(product).tax_category_id)
        .to eq(product.variants.last.tax_category_id)
    end

    it 'copies category (primary taxon) from the last variant' do
      expect(helper.prepare_new_variant(product).primary_taxon_id).to eq(taxon.id)
    end

    it 'copies unit type from the last variant' do
      new_variant = helper.prepare_new_variant(product)
      expect(new_variant.variant_unit).to eq("weight")
      expect(new_variant.variant_unit_scale).to eq(1000.0)
    end

    it 'copies unit value from the last variant so the unit field renders non-empty' do
      expect(helper.prepare_new_variant(product).unit_value).to eq(1000.0)
    end

    it 'copies price from the last variant' do
      expect(helper.prepare_new_variant(product).price).to eq(9.99)
    end

    it 'copies producer (enterprise) from the last variant' do
      expect(helper.prepare_new_variant(product).enterprise_id).to eq(supplier.id)
    end

    it 'sets on_hand_desired to 0' do
      expect(helper.prepare_new_variant(product).on_hand_desired).to eq(0)
    end

    it 'does not copy on_demand, so new variants default to out of stock' do
      expect(helper.prepare_new_variant(product).on_demand_desired).to be_falsey
    end

    it 'overrides producer with an explicit integer producer_id' do
      other_supplier = create(:supplier_enterprise)
      expect(helper.prepare_new_variant(product, other_supplier.id).enterprise_id)
        .to eq(other_supplier.id)
    end

    context 'when the product has no existing variants' do
      let(:product) { create(:product) }

      before { product.variants.destroy_all }

      it 'returns a variant with only enterprise_id set' do
        new_variant = helper.prepare_new_variant(product, supplier.id)
        expect(new_variant.enterprise_id).to eq(supplier.id)
        expect(new_variant.primary_taxon_id).to be_nil
      end
    end
  end

  describe "#variant_displayable?" do
    let(:enterprise) { create(:supplier_enterprise) }
    let(:variant) { create(:variant, enterprise: ) }
    let(:producer_id) { nil }
    let(:allowed_producers) { [enterprise] }
    let(:allowed_source_producers) { [] }
    let(:managed_product_enterprises) { [] }
    subject {
      helper.variant_displayable?(variant, producer_id, allowed_producers, allowed_source_producers)
    }

    before do
      allow(helper).to receive(:managed_product_enterprises).and_return(managed_product_enterprises)
    end

    it "returns true" do
      expect(subject).to eq(true)
    end

    context "with linked variant" do
      context "with the user's linked variant" do
        let(:hub) { create(:distributor_enterprise) }
        let(:source_enterprise) { create(:supplier_enterprise) }
        let(:variant) { create(:variant, enterprise: source_enterprise, hub: hub) }
        let(:allowed_source_producers) { [source_enterprise] }
        let(:managed_product_enterprises) { [enterprise, hub] }

        it "returns true" do
          expect(subject).to eq(true)
        end
      end

      context "wiht someone else's linked variant" do
        let(:other_enterprise) { create(:supplier_enterprise) }
        let(:variant) { create(:variant, enterprise:, hub: other_enterprise) }

        it "returns false" do
          expect(subject).to eq(false)
        end
      end
    end

    context "with a variant the user has permission to manage" do
      let(:friend_enterprise) { create(:supplier_enterprise) }
      let(:variant) { create(:variant, enterprise: friend_enterprise) }
      let(:allowed_producers) { [enterprise, friend_enterprise] }

      it "returns true" do
        expect(subject).to eq(true)
      end
    end

    context "with a variant the user doesn't have permission manage" do
      let(:other_enterprise) { create(:supplier_enterprise) }
      let(:variant) { create(:variant, enterprise: other_enterprise) }

      it "returns false" do
        expect(subject).to eq(false)
      end
    end

    context "with a variant with no enterprise" do
      let(:variant) { build(:variant, enterprise: nil) }

      it "returns true" do
        expect(subject).to eq(true)
      end
    end

    describe "enterprise filter" do
      context "enterprise selected" do
        let(:producer_id) { enterprise.id.to_s }

        it "returns true" do
          expect(subject).to eq(true)
        end
      end
      context "other enterprise selected" do
        let(:producer_id) { "123" }

        it "returns false" do
          expect(subject).to eq(false)
        end
      end
    end
  end

  describe "#variant_readonly?" do
    let(:enterprise) { create(:supplier_enterprise) }
    let(:variant) { create(:variant, enterprise: ) }
    let(:allowed_producers) { [enterprise] }
    let(:allowed_source_producers) { [] }
    let(:friend_enterprise) { create(:supplier_enterprise) }

    it "returns false" do
      expect(helper.variant_readonly?(variant, allowed_producers,
                                      allowed_source_producers)).to eq(false)
    end

    context "with linked variant" do
      let(:variant) { create(:variant, enterprise: friend_enterprise, hub: enterprise) }
      let(:allowed_source_producers) { [friend_enterprise] }

      it "returns false" do
        expect(helper.variant_readonly?(variant, allowed_producers,
                                        allowed_source_producers)).to eq(false)
      end
    end

    context "with variant the user has permission to create linked variants" do
      let(:variant) { create(:variant, enterprise: friend_enterprise) }
      let(:allowed_source_producers) { [friend_enterprise] }

      it "returns true" do
        expect(helper.variant_readonly?(variant, allowed_producers,
                                        allowed_source_producers)).to eq(true)
      end
    end
  end
end
