# frozen_string_literal: true

RSpec.describe "spree/shared/_variant_thumbnail.html.haml" do
  include FileHelper

  let(:variant) { create(:variant) }
  let(:product) { variant.product }

  context "when the variant has its own image" do
    let!(:product_image) { Spree::Image.create!(attachment: black_logo_file, viewable: product) }
    let!(:variant_image) { Spree::Image.create!(attachment: white_logo_file, viewable: variant) }

    it "shows the variant image" do
      render partial: "spree/shared/variant_thumbnail", locals: { variant: variant.reload }

      expect(rendered).to have_css "img[src='#{variant_image.url(:mini)}']"
    end
  end

  context "when only the product has an image" do
    let!(:product_image) { Spree::Image.create!(attachment: black_logo_file, viewable: product) }

    it "shows the product image" do
      render partial: "spree/shared/variant_thumbnail", locals: { variant: variant.reload }

      expect(rendered).to have_css "img[src='#{product_image.url(:mini)}']"
    end
  end

  context "when neither has an image" do
    it "shows the default image" do
      render partial: "spree/shared/variant_thumbnail", locals: { variant: variant.reload }

      expect(rendered).to have_css "img[src='#{Spree::Image.default_image_url(:mini)}']"
    end
  end
end
