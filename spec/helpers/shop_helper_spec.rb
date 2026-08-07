# frozen_string_literal: false

RSpec.describe ShopHelper do
  describe "product_carousel_images_data" do
    include FileHelper

    let(:product) { create(:simple_product, name: "Test Product") }

    context "when the product has no images" do
      it "returns an array with a single default image" do
        result = helper.product_carousel_images_data(product)

        expect(result.size).to eq 1
        expect(result.first[:alt]).to eq "Test Product"
        expect(result.first[:caption]).to be_nil
      end
    end

    context "when the product has one image" do
      let(:product) { create(:product_with_image, name: "Test Product") }

      it "returns image data without a caption" do
        result = helper.product_carousel_images_data(product)

        expect(result.size).to eq 1
        expect(result.first[:alt]).to eq "Test Product"
        expect(result.first[:caption]).to be_nil
        expect(result.first[:url]).to be_present
      end

      it "uses image alt when present" do
        product.images.first.update!(alt: "Custom alt")
        result = helper.product_carousel_images_data(product)

        expect(result.first[:alt]).to eq "Custom alt"
      end
    end

    context "when the product has multiple images" do
      let(:product) { create(:simple_product, name: "Test Product") }

      before do
        3.times do
          Spree::Image.create!(
            attachment: white_logo_file,
            viewable: product
          )
        end
      end

      it "returns image data with numbered captions" do
        result = helper.product_carousel_images_data(product)

        expect(result.size).to eq 3
        expect(result[0][:caption]).to eq "Test Product - 1"
        expect(result[1][:caption]).to eq "Test Product - 2"
        expect(result[2][:caption]).to eq "Test Product - 3"
      end
    end
  end

  describe "shop_tabs" do
    context "distributor with groups" do
      let(:group) { create(:enterprise_group) }
      let(:distributor) { create(:distributor_enterprise, groups: [group]) }

      before do
        allow(helper).to receive(:current_distributor).and_return distributor
      end

      it "should return the groups tab" do
        expect(helper.shop_tabs).to include(name: "groups", show: true, title: "Groups")
      end
    end

    context "distributor without groups" do
      let(:distributor) { create(:distributor_enterprise) }

      before do
        allow(helper).to receive(:current_distributor).and_return distributor
      end

      it "should not return the groups tab" do
        expect(helper.shop_tabs).not_to include(name: "groups", show: true, title: "Groups")
      end
    end

    context "distributor with shopfront message" do
      let(:distributor) { create(:distributor_enterprise, preferred_shopfront_message: "Hello!") }

      before do
        allow(helper).to receive(:current_distributor).and_return distributor
      end

      it "should show the home tab" do
        expect(helper.shop_tabs).to include(name: "home", show: true, title: "Home", default: true)
      end
    end
  end
end
