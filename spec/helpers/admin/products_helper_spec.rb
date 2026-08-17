# frozen_string_literal: true

RSpec.describe Admin::ProductsHelper do
  include FileHelper

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
    subject {
      helper.variant_displayable?(variant, producer_id, allowed_producers, allowed_source_producers)
    }

    it "returns true" do
      expect(subject).to eq(true)
    end

    context "with linked variant" do
      context "with the user's linked variant" do
        let(:source_enterprise) { create(:supplier_enterprise) }
        let(:variant) { create(:variant, enterprise: source_enterprise) }
        let(:allowed_source_producers) { [source_enterprise] }

        it "returns true" do
          expect(subject).to eq(true)
        end
      end

      context "with someone else's linked variant" do
        let(:other_enterprise) { create(:supplier_enterprise) }
        let(:variant) { create(:variant, enterprise: other_enterprise) }

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

    context "with variant the user has permission to create linked variants" do
      let(:variant) { create(:variant, enterprise: friend_enterprise) }
      let(:allowed_source_producers) { [friend_enterprise] }

      it "returns true" do
        expect(helper.variant_readonly?(variant, allowed_producers,
                                        allowed_source_producers)).to eq(true)
      end
    end
  end

  describe '#image_upload_path' do
    context 'when imageable is a product' do
      let(:product) { create(:product) }

      it 'returns admin_product_images_path' do
        expect(helper.image_upload_path(product))
          .to eq "/admin/products/#{product.id}/images"
      end
    end

    context 'when imageable is a variant' do
      let(:variant) { create(:variant, product: create(:product)) }

      it 'returns admin_product_images_path with variant_id' do
        expect(helper.image_upload_path(variant))
          .to eq "/admin/products/#{variant.product_id}/images?variant_id=#{variant.id}"
      end
    end
  end

  describe '#image_owner_edit_path' do
    let(:product) { create(:product) }

    context 'without a variant' do
      it 'returns the product edit path' do
        expect(helper.image_owner_edit_path(product))
          .to eq "/admin/products/#{product.id}/edit"
      end
    end

    context 'with a variant' do
      let(:variant) { create(:variant, product:) }

      it 'returns the variant edit path' do
        expect(helper.image_owner_edit_path(product, variant))
          .to eq "/admin/products/#{product.id}/variants/#{variant.id}/edit"
      end
    end
  end

  describe '#default_image_caption' do
    let(:product) { create(:product, name: "Asparagus") }

    context 'without a variant' do
      it 'defaults to the product name' do
        expect(helper.default_image_caption(product)).to eq "Asparagus"
      end
    end

    context 'with a variant that has a display name' do
      let(:variant) { create(:variant, product:, display_name: "Small bunch") }

      it 'defaults to the display name' do
        expect(helper.default_image_caption(product, variant)).to eq "Small bunch"
      end
    end

    context 'with a variant that has no display name' do
      let(:variant) { create(:variant, product:, display_name: nil) }

      it 'has no default' do
        expect(helper.default_image_caption(product, variant)).to eq ""
      end
    end
  end

  describe '#image_form_path' do
    let(:product) { create(:product) }

    context 'when imageable is a product' do
      context 'without existing image' do
        it 'returns new_admin_product_image_path' do
          expect(helper.image_form_path(product))
            .to eq "/admin/products/#{product.id}/images/new"
        end
      end

      context 'with existing image' do
        let!(:product) { create(:product_with_image) }

        it 'returns edit_admin_product_image_path' do
          expect(helper.image_form_path(product))
            .to eq "/admin/products/#{product.id}/images/#{product.image.id}/edit"
        end
      end
    end

    context 'when imageable is a variant' do
      let(:variant) { create(:variant, product:) }

      context 'without existing image' do
        it 'returns new_admin_product_image_path with variant_id' do
          expect(helper.image_form_path(variant))
            .to eq "/admin/products/#{product.id}/images/new?variant_id=#{variant.id}"
        end
      end

      context 'with existing image' do
        let!(:variant_image) {
          Spree::Image.create(
            attachment: white_logo_file,
            viewable: variant
          )
        }

        it 'returns edit_admin_product_image_path with variant_id' do
          path = helper.image_form_path(variant.reload)
          expect(path).to include("/admin/products/#{product.id}/images/#{variant_image.id}/edit")
          expect(path).to include("variant_id=#{variant.id}")
        end
      end
    end
  end

  describe '#image_modal_resource_name' do
    let(:product) { create(:product, name: "Apples") }

    context 'when variant is nil' do
      it 'returns the product name' do
        expect(helper.image_modal_resource_name(nil, product)).to eq "Apples"
      end
    end

    context 'when variant has a display_name' do
      let(:variant) { create(:variant, product:, display_name: "Red") }

      it 'returns product name with variant display_name' do
        expect(helper.image_modal_resource_name(variant, product)).to eq "Apples - Red"
      end
    end

    context 'when variant display_name is blank' do
      let(:variant) { create(:variant, product:, display_name: "") }

      it 'returns only the product name' do
        expect(helper.image_modal_resource_name(variant, product)).to eq "Apples"
      end
    end
  end
end
