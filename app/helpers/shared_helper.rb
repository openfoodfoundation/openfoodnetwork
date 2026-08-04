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

    return [default_carousel_image(size, product)] if images.empty?

    images.map.with_index do |image, index|
      {
        url: image.url(size),
        alt: image.alt.presence || product.name,
        caption: images.many? ? "#{product.name} - #{index + 1}" : nil
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
end
