# frozen_string_literal: true

RSpec.describe Admin::ProductsHelper do
  include FileHelper

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
    let(:product) {
      create(:taxed_product, zone:, price: 12.54, tax_rate_amount: 0,
                             included_in_price: true)
    }

    context 'when tax category is present for first varient' do
      it 'sets tax category for new variant' do
        first_variant_tax_id = product.variants.first.tax_category_id
        expect(helper.prepare_new_variant(product, []).tax_category_id).to eq(first_variant_tax_id)
      end
    end
  end

  describe "#variant_displayable?" do
    let(:enterprise) { create(:supplier_enterprise) }
    let(:variant) { create(:variant, enterprise: ) }
    let(:allowed_producers) { [enterprise] }
    let(:allowed_source_producers) { [] }
    let(:managed_product_enterprises) { [] }

    before do
      allow(helper).to receive(:managed_product_enterprises).and_return(managed_product_enterprises)
    end

    it "returns true" do
      expect(helper.variant_displayable?(variant, allowed_producers,
                                         allowed_source_producers)).to eq(true)
    end

    context "with linked variant" do
      context "with the user's linked variant" do
        let(:hub) { create(:distributor_enterprise) }
        let(:source_enterprise) { create(:supplier_enterprise) }
        let(:variant) { create(:variant, enterprise: source_enterprise, hub: hub) }
        let(:allowed_source_producers) { [source_enterprise] }
        let(:managed_product_enterprises) { [enterprise, hub] }

        it "returns true" do
          expect(helper.variant_displayable?(variant, allowed_producers,
                                             allowed_source_producers)).to eq(true)
        end
      end

      context "wiht someone else's linked variant" do
        let(:other_enterprise) { create(:supplier_enterprise) }
        let(:variant) { create(:variant, enterprise:, hub: other_enterprise) }

        it "returns false" do
          expect(helper.variant_displayable?(variant, allowed_producers,
                                             allowed_source_producers)).to eq(false)
        end
      end
    end

    context "with a variant the user has permission to manage" do
      let(:friend_enterprise) { create(:supplier_enterprise) }
      let(:variant) { create(:variant, enterprise: friend_enterprise) }
      let(:allowed_producers) { [enterprise, friend_enterprise] }

      it "returns true" do
        expect(helper.variant_displayable?(variant, allowed_producers,
                                           allowed_source_producers)).to eq(true)
      end
    end

    context "with a variant the user doesn't have permission manage" do
      let(:other_enterprise) { create(:supplier_enterprise) }
      let(:variant) { create(:variant, enterprise: other_enterprise) }

      it "returns false" do
        expect(helper.variant_displayable?(variant, allowed_producers,
                                           allowed_source_producers)).to eq(false)
      end
    end

    context "with a variant with no enterprise" do
      let(:variant) { build(:variant, enterprise: nil) }

      it "returns true" do
        expect(helper.variant_displayable?(variant, allowed_producers,
                                           allowed_source_producers)).to eq(true)
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
