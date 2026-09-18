# frozen_string_literal: true

RSpec.describe SharedHelper do
  include FileHelper

  describe '#product_carousel_images_data' do
    let(:product) { create(:simple_product, name: "Test Product") }

    context 'when product has no images' do
      it 'returns a default fallback image entry' do
        data = helper.product_carousel_images_data(product)

        expect(data).to eq([
                             {
                               url: Spree::Image.default_image_url(:large),
                               alt: "Test Product",
                               caption: nil
                             }
                           ])
      end
    end

    context 'when product has one image' do
      let(:product) { create(:product_with_image, name: "Test Product") }

      it 'returns image data with the product name as the default caption' do
        data = helper.product_carousel_images_data(product)

        expect(data.size).to eq 1
        expect(data.first[:url]).to be_present
        expect(data.first[:alt]).to eq "Test Product"
        expect(data.first[:caption]).to eq "Test Product"
      end

      it 'uses image alt when present' do
        product.images.first.update!(alt: "Custom alt")
        data = helper.product_carousel_images_data(product)

        expect(data.first[:alt]).to eq "Custom alt"
      end

      it 'prefers the image caption over the default caption' do
        product.images.first.update!(caption: "Custom caption")
        data = helper.product_carousel_images_data(product)

        expect(data.first[:caption]).to eq "Custom caption"
      end

      it 'keeps a deliberately cleared caption empty' do
        product.images.first.update!(caption: "")
        data = helper.product_carousel_images_data(product)

        expect(data.first[:caption]).to eq ""
      end
    end

    context 'when product has multiple images' do
      before do
        3.times do
          Spree::Image.create!(
            attachment: white_logo_file,
            viewable: product
          )
        end
      end

      it 'returns image data with the product name as the default caption' do
        data = helper.product_carousel_images_data(product)

        expect(data.size).to eq 3
        expect(data[0][:caption]).to eq "Test Product"
        expect(data[1][:caption]).to eq "Test Product"
        expect(data[2][:caption]).to eq "Test Product"
      end

      it 'prefers the image caption over the default caption' do
        product.images.first.update!(caption: "Custom caption")
        data = helper.product_carousel_images_data(product)

        expect(data[0][:caption]).to eq "Custom caption"
        expect(data[1][:caption]).to eq "Test Product"
      end
    end

    context 'when product has no images but a variant has images' do
      let(:variant) { product.variants.first }

      before do
        Spree::Image.create!(
          attachment: white_logo_file,
          viewable: variant
        )
      end

      it 'returns the variant image data' do
        data = helper.product_carousel_images_data(product)

        expect(data.size).to eq 1
        expect(data.first[:url]).to be_present
        expect(data.first[:alt]).to eq "Test Product"
        # The variant has no display name, so it gets no caption.
        expect(data.first[:caption]).to be_blank
      end
    end

    context 'when product has images and a variant also has images' do
      let(:variant) { product.variants.first }

      before do
        Spree::Image.create!(
          attachment: white_logo_file,
          viewable: product
        )
        Spree::Image.create!(
          attachment: white_logo_file,
          viewable: variant
        )
      end

      it 'returns product images followed by variant images' do
        data = helper.product_carousel_images_data(product)

        expect(data.size).to eq 2
        expect(data[0][:caption]).to eq "Test Product"
        # The variant has no display name, so its image gets no caption.
        expect(data[1][:caption]).to be_blank
      end
    end

    context 'when a single variant image belongs to a variant with a display_name' do
      let!(:variant) { create(:variant, product:, display_name: 'Red') }

      before do
        Spree::Image.create!(
          attachment: white_logo_file,
          viewable: variant
        )
      end

      it "uses the variant display name as the caption" do
        data = helper.product_carousel_images_data(product)

        expect(data.size).to eq 1
        expect(data.first[:caption]).to eq "Red"
        expect(data.first[:alt]).to eq "Test Product"
      end
    end

    context 'when a single variant image belongs to a variant without a display_name' do
      let!(:variant) { create(:variant, product:, display_name: nil) }

      before do
        Spree::Image.create!(
          attachment: white_logo_file,
          viewable: variant
        )
      end

      it "has no caption rather than borrowing the product name" do
        data = helper.product_carousel_images_data(product)

        expect(data.size).to eq 1
        expect(data.first[:caption]).to be_blank
        expect(data.first[:alt]).to eq "Test Product"
      end
    end

    context 'when a variant image belongs to a variant with a display_name' do
      let(:variant) { create(:variant, product:, display_name: 'Red') }

      before do
        Spree::Image.create!(
          attachment: white_logo_file,
          viewable: product
        )
        Spree::Image.create!(
          attachment: white_logo_file,
          viewable: variant
        )
      end

      it "uses the variant display name as the variant image's caption" do
        data = helper.product_carousel_images_data(product)

        expect(data.size).to eq 2
        expect(data[0][:caption]).to eq "Test Product"
        expect(data[1][:caption]).to eq "Red"
        expect(data[1][:alt]).to eq "Test Product"
      end
    end

    context 'when available_variant_ids is given' do
      let(:available_variant) { product.variants.first }
      let!(:unavailable_variant) { create(:variant, product:, display_name: 'Hidden') }

      before do
        Spree::Image.create!(attachment: white_logo_file, viewable: product)
        Spree::Image.create!(attachment: white_logo_file, viewable: available_variant)
        Spree::Image.create!(attachment: white_logo_file, viewable: unavailable_variant)
      end

      it 'keeps product images and only available variants images' do
        data = helper.product_carousel_images_data(
          product, available_variant_ids: [available_variant.id]
        )

        # Product image + the available variant's image, but not the hidden variant's.
        expect(data.size).to eq 2
        expect(data.pluck(:caption)).to contain_exactly("Test Product", nil)
      end

      it 'excludes all variant images when no variant is available' do
        data = helper.product_carousel_images_data(product, available_variant_ids: [])

        expect(data.size).to eq 1
        expect(data.first[:caption]).to eq "Test Product"
      end

      it 'falls back to the default image when nothing survives filtering' do
        product.images.destroy_all
        data = helper.product_carousel_images_data(product, available_variant_ids: [])

        expect(data).to eq([
                             {
                               url: Spree::Image.default_image_url(:large),
                               alt: "Test Product",
                               caption: nil
                             }
                           ])
      end
    end

    context 'when available_variant_ids is nil (no filtering)' do
      let!(:variant) { create(:variant, product:, display_name: 'Red') }

      before do
        Spree::Image.create!(attachment: white_logo_file, viewable: product)
        Spree::Image.create!(attachment: white_logo_file, viewable: variant)
      end

      it 'shows every variant image, preserving the pre-filtering behaviour' do
        data = helper.product_carousel_images_data(product, available_variant_ids: nil)

        expect(data.size).to eq 2
      end
    end
  end

  describe '#product_carousel_images?' do
    let(:product) { create(:simple_product, name: "Test Product") }
    let(:variant) { product.variants.first }

    it 'is false when the product has no real images' do
      expect(helper.product_carousel_images?(product)).to be false
    end

    it 'is true when the product has a product-level image' do
      Spree::Image.create!(attachment: white_logo_file, viewable: product)

      expect(helper.product_carousel_images?(product)).to be true
    end

    it 'is false when the only image belongs to an unavailable variant' do
      Spree::Image.create!(attachment: white_logo_file, viewable: variant)

      expect(helper.product_carousel_images?(product, available_variant_ids: [])).to be false
    end

    it 'is true when an available variant has an image' do
      Spree::Image.create!(attachment: white_logo_file, viewable: variant)

      expect(
        helper.product_carousel_images?(product, available_variant_ids: [variant.id])
      ).to be true
    end
  end
end
