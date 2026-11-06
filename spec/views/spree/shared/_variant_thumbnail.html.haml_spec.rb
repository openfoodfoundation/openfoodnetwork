# frozen_string_literal: true

RSpec.describe "spree/shared/_variant_thumbnail.html.haml" do
  include FileHelper

  let(:variant) { create(:variant) }

  it "shows the variant image" do
    Spree::Image.create!(attachment: white_logo_file, viewable: variant)

    render partial: "spree/shared/variant_thumbnail", locals: { variant: variant.reload }

    expect(rendered).to have_css "img[src='#{variant.image_url(:mini)}']"
  end
end
