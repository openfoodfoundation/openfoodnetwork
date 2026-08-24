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

      it 'returns image data without a caption' do
        data = helper.product_carousel_images_data(product)

        expect(data.size).to eq 1
        expect(data.first[:url]).to be_present
        expect(data.first[:alt]).to eq "Test Product"
        expect(data.first[:caption]).to be_nil
      end

      it 'uses image alt when present' do
        product.images.first.update!(alt: "Custom alt")
        data = helper.product_carousel_images_data(product)

        expect(data.first[:alt]).to eq "Custom alt"
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

      it 'returns image data with numbered captions' do
        data = helper.product_carousel_images_data(product)

        expect(data.size).to eq 3
        expect(data[0][:caption]).to eq "Test Product - 1"
        expect(data[1][:caption]).to eq "Test Product - 2"
        expect(data[2][:caption]).to eq "Test Product - 3"
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
        expect(data.first[:caption]).to be_nil
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
        expect(data[0][:caption]).to eq "Test Product - 1"
        expect(data[1][:caption]).to eq "Test Product - 2"
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

      it 'falls back to the product name for a variant image\'s caption and alt' do
        data = helper.product_carousel_images_data(product)

        expect(data.size).to eq 2
        expect(data[0][:caption]).to eq "Test Product - 1"
        expect(data[1][:caption]).to eq "Test Product - 2"
        expect(data[1][:alt]).to eq "Test Product"
      end
    end
  end
end
