# frozen_string_literal: true

module Admin
  module ProductsHelper
    def product_image_form_path(product)
      if product.image.present?
        edit_admin_product_image_path(product.id, product.image.id)
      else
        new_admin_product_image_path(product.id)
      end
    end

    def prepare_new_variant(product, producer_id = nil)
      product.variants.build do |new_variant|
        new_variant.enterprise_id = producer_id
        new_variant.tax_category_id = product.variants.first.tax_category_id
      end
    end

    def unit_value_with_description(variant)
      return variant.unit_description.to_s if variant.unit_value.nil?

      scaled_unit_value = variant.unit_value / (variant.variant_unit_scale || 1)
      precised_unit_value = number_with_precision(
        scaled_unit_value,
        precision: nil,
        strip_insignificant_zeros: true,
        significant: false,
      )

      [precised_unit_value, variant.unit_description].compact_blank.join(" ")
    end

    def products_return_to_url
      session[:products_return_to_url] || admin_products_url
    end

    def product_carousel_images_data(product, size: :large)
      images = product.images.to_a
      show_caption = images.many?

      return [default_carousel_image(size, product)] if images.empty?

      images.map.with_index do |image, index|
        {
          url: image.url(size),
          alt: product_image_alt_text(image, product),
          caption: show_caption ? "#{product.name} - #{index + 1}" : nil
        }
      end
    end

    # if user hasn't saved any preferences on products page and there's only one producer;
    # we need to hide producer column
    def hide_producer_column?(allowed_producers)
      spree_current_user.column_preferences.bulk_edit_product.empty? && allowed_producers.one?
    end

    # check if the user is in the "admins" group or if it's enabled for any of
    # the enterprises the user manages
    def variant_tag_enabled?(user)
      feature?(:variant_tag, user) || feature?(:variant_tag, *user.enterprises)
    end

    def managed_product_enterprises
      @managed_product_enterprises ||= OpenFoodNetwork::Permissions.new(spree_current_user)
        .managed_product_enterprises
    end

    # Query only name of the model to avoid loading the whole record
    def selected_option(id, model)
      return [] unless id

      name = model.where(id: id).pick(:name)
      return [] unless name

      [[name, id]]
    end

    def variant_displayable?(variant, producer_id, allowed_producers, allowed_source_producers)
      # Filter out other enterprises if an enterprise filter was selected.
      # (Note we still don't filter category selections here)
      return false if producer_id.present? && variant.enterprise_id.to_s != producer_id

      # Filter out variant a user has not permission to update, but keep variant with no enterprise
      return false if variant.enterprise.present? &&
                      !(allowed_producers.include?(variant.enterprise) ||
                        allowed_source_producers.include?(variant.enterprise)
                       )

      # Filter out other hub's variants that are linked to mine
      return false if variant.hub.present? && managed_product_enterprises.exclude?(variant.hub)

      true
    end

    # Read only if variant comes from enterprise giving "create_linked_variants" permission and
    # isn't a variant we can manage
    def variant_readonly?(variant, allowed_producers, allowed_source_producers)
      return true if allowed_producers.exclude?(variant.enterprise) &&
                     allowed_source_producers.include?(variant.enterprise) && variant.hub_id.blank?

      false
    end

    private

    def product_image_alt_text(image, product)
      image.alt.presence || product.name
    end

    def default_carousel_image(size, product)
      {
        url: Spree::Image.default_image_url(size),
        alt: product.name,
        caption: nil
      }
    end
  end
end
