# frozen_string_literal: true

class CarouselComponent < ViewComponent::Base
  def initialize(images:, show_captions: false, options: nil, show_navigation: true,
                 show_pagination: true, **html_options)
    @images = normalize_images(images)
    @show_captions = show_captions
    @options = options || {}
    @show_navigation = show_navigation
    @show_pagination = show_pagination
    @html_options = html_options
  end

  attr_reader :images

  private

  def show_captions?
    @show_captions
  end

  def show_navigation?
    @show_navigation && multiple_images?
  end

  def show_pagination?
    @show_pagination && multiple_images?
  end

  def root_attributes
    attributes = @html_options.deep_dup
    data = attributes.delete(:data) || {}

    {
      class: [root_css_class, "swiper", attributes.delete(:class)].compact.join(" "),
      data: default_data_attributes.merge(data)
    }.merge(attributes)
  end

  def default_data_attributes
    {
      :controller => controller_identifier,
      options_data_attribute => carousel_options.to_json
    }
  end

  def carousel_options
    { loop: multiple_images? }.deep_merge(@options.deep_symbolize_keys)
  end

  def multiple_images?
    images.many?
  end

  def target_attribute(name)
    { "data-#{controller_identifier}-target": name }
  end

  def normalize_images(images)
    Array(images).map do |image|
      attrs = image.to_h.symbolize_keys
      {
        url: attrs.fetch(:url),
        alt: attrs.fetch(:alt, ""),
        caption: attrs[:caption]
      }
    end
  end

  def root_css_class
    "ofn-carousel"
  end

  def controller_identifier
    "carousel"
  end

  def options_data_attribute
    "carousel-options-value"
  end
end
