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

  # Names the producer of a ViewData::Product's variants, or says that there are several.
  # Linked variants are produced by their source variant's enterprise, not by the reselling
  # hub that owns them, so this can name one producer where the variants have two owners.
  def product_producer_name(product)
    return t("products_multiple_producers") unless product.single_producer?

    product.producers.first.name
  end

  def product_carousel_images_data(product, available_variant_ids: nil, size: :large)
    images = carousel_images(product, available_variant_ids)

    return [default_carousel_image(size, product)] if images.empty?

    images.map do |image|
      {
        url: image.url(size),
        alt: image.alt.presence || product.name,
        caption: image.caption.nil? ? default_caption(image) : image.caption
      }
    end
  end

  # Whether the carousel has any real image (product-level or an available variant's) once
  # unavailable-variant images are filtered out. Drives the carousel's placeholder styling.
  def product_carousel_images?(product, available_variant_ids: nil)
    carousel_images(product, available_variant_ids).any?
  end

  private

  # Product-level images are always shown. Variant images are shown only when their variant
  # is available for purchase. A nil `available_variant_ids` means "don't filter" (e.g. the
  # admin preview, which has no order cycle) and preserves the pre-filtering behaviour.
  def carousel_images(product, available_variant_ids)
    product_images = product.images.to_a
    variant_images = if available_variant_ids.nil?
                       product.variant_images.to_a
                     else
                       product.variant_images.where(
                         viewable_id: available_variant_ids,
                         viewable_type: 'Spree::Variant'
                       ).to_a
                     end

    product_images + variant_images
  end

  def default_carousel_image(size, product)
    {
      url: Spree::Image.default_image_url(size),
      alt: product.name,
      caption: nil
    }
  end

  # Mirrors Admin::ProductsHelper#default_image_caption: a variant with no display
  # name gets no caption rather than borrowing the product's name.
  def default_caption(image)
    viewable = image.viewable
    return viewable.name if viewable.is_a?(Spree::Product)

    viewable.display_name.presence
  end
end
