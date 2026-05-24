# frozen_string_literal: true

RSpec.describe ThumbnailCarouselComponent, type: :component do
  let(:images) do
    [
      { url: "/image-1.jpg", alt: "Image 1", caption: "Caption 1" },
      { url: "/image-2.jpg", alt: "Image 2", caption: "Caption 2" }
    ]
  end

  it "renders carousel slides and thumbnails" do
    render_inline(described_class.new(images:))

    expect(page).to have_selector ".ofn-thumbnail-carousel.swiper[data-controller='thumbnail-carousel']"
    expect(page).to have_selector ".swiper-slide", count: 2
    expect(page).to have_selector ".ofn-thumbnail-carousel__thumb", count: 2
  end

  it "supports optional captions" do
    render_inline(described_class.new(images:, show_captions: true))

    expect(page).to have_selector ".ofn-thumbnail-carousel__caption", text: "Caption 1"
    expect(page).to have_selector ".ofn-thumbnail-carousel__caption", text: "Caption 2"
  end
end
