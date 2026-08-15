# frozen_string_literal: true

module SharedHelper
  def enterprise_user?
    spree_current_user&.enterprises&.count.to_i > 0
  end

  def admin_user?
    spree_current_user&.admin?
  end

  def current_shop_products_path
    "#{main_app.enterprise_shop_path(current_distributor)}#/shop_panel"
  end

  def product_carousel_images_data(product, size: :large)
    images = product.images.to_a + product.variant_images.to_a
    show_caption = images.many?

    return [default_carousel_image(size, product)] if images.empty?

    images.map do |image|
      {
        url: image.url(size),
        alt: image.alt.presence || product.name,
        caption: show_caption ? (image.caption.presence || default_caption(image)) : nil
      }
    end
  end

  private

  def default_carousel_image(size, product)
    {
      url: Spree::Image.default_image_url(size),
      alt: product.name,
      caption: nil
    }
  end

  def default_caption(image)
    viewable = image.viewable
    return viewable.name if viewable.is_a?(Spree::Product)

    viewable.display_name.presence || viewable.product.name
  end
end
