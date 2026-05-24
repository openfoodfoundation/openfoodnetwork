# frozen_string_literal: true

class ThumbnailCarouselComponent < CarouselComponent
  def initialize(images:, show_captions: false, options: {}, show_navigation: true,
                 show_pagination: false, **html_options)
    super
  end

  private

  def root_css_class
    "ofn-thumbnail-carousel"
  end

  def controller_identifier
    "thumbnail-carousel"
  end

  def options_data_attribute
    "thumbnail-carousel-options-value"
  end
end
