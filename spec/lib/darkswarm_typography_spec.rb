# frozen_string_literal: true

RSpec.describe "Darkswarm body font definitions" do
  let(:typography_scss) do
    Rails.root.join("app/webpacker/css/darkswarm/typography.scss").read
  end
  let(:body_font_variable_scss) do
    Rails.root.join("app/webpacker/css/darkswarm/shop_partials/_typography.scss").read
  end

  it "sets the bodyFont mixin to Open Sans, with no Roboto reference" do
    mixin = typography_scss[/@mixin bodyFont \{.*?\}/m]

    expect(mixin).to include('font-family: "Open Sans", "Helvetica Neue", Arial, sans-serif;')
    expect(mixin).not_to include("Roboto")
  end

  it "sets the $body-font variable to Open Sans, with no Roboto reference" do
    variable_line = body_font_variable_scss[/^\$body-font:.*$/]

    expect(variable_line).to eq '$body-font: "Open Sans", "Helvetica Neue", Arial, sans-serif;'
    expect(variable_line).not_to include("Roboto")
  end

  it "does not define a .text-skinny class, so no Open Sans weight 300 is needed" do
    expect(typography_scss).not_to include(".text-skinny")
  end
end
