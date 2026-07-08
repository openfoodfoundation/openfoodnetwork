# frozen_string_literal: true

RSpec.describe CarouselComponent, type: :component do
  let(:images) do
    [
      { url: "/image-1.jpg", alt: "Image 1", caption: "Caption 1" },
      { url: "/image-2.jpg", alt: "Image 2", caption: "Caption 2" }
    ]
  end

  it "renders a generic carousel with slides" do
    render_inline(described_class.new(images:))

    expect(page).to have_selector ".ofn-carousel.swiper[data-controller='carousel']"
    expect(page).to have_selector ".swiper-slide", count: 2
  end

  it "shows captions when configured" do
    render_inline(described_class.new(images:, show_captions: true))

    expect(page).to have_selector ".ofn-carousel__caption", text: "Caption 1"
    expect(page).to have_selector ".ofn-carousel__caption", text: "Caption 2"
  end

  it "hides captions by default" do
    render_inline(described_class.new(images:))

    expect(page).not_to have_selector ".ofn-carousel__caption"
  end
end
