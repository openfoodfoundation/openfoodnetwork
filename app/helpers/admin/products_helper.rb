# frozen_string_literal: true

module Admin
  module ProductsHelper
    include SharedHelper

    def image_form_path(imageable)
      if imageable.is_a?(Spree::Variant)
        product_id = imageable.product_id
        extra = { variant_id: imageable.id }
      else
        product_id = imageable.id
        extra = {}
      end

      if imageable.image.present?
        edit_admin_product_image_path(product_id, imageable.image.id, extra)
      else
        new_admin_product_image_path(product_id, extra)
      end
    end

    # Where the image edit page came from: the product or variant edit page.
    def image_owner_edit_path(product, variant = nil)
      if variant
        edit_admin_product_variant_path(product, variant)
      else
        edit_admin_product_path(product)
      end
    end

    # Default caption offered on the image edit page when none has been saved yet.
    # Variants without a display name intentionally get no default.
    def default_image_caption(product, variant = nil)
      return variant.display_name.to_s if variant

      product.name
    end

    # A caption that was deliberately cleared is stored as an empty string and must
    # stay empty; only a caption that was never set falls back to the default.
    def image_caption_field_value(image, product, variant = nil)
      return image.caption unless image.caption.nil?

      default_image_caption(product, variant)
    end

    def image_upload_path(imageable)
      if imageable.is_a?(Spree::Variant)
        admin_product_images_path(imageable.product_id, variant_id: imageable.id)
      else
        admin_product_images_path(imageable.id)
      end
    end

    NEW_VARIANT_TEMPLATE_FIELDS = %i[
      tax_category_id
      primary_taxon_id
      enterprise_id
      variant_unit
      variant_unit_scale
      variant_unit_name
      unit_value
      price
    ].freeze

    def prepare_new_variant(product, producer_id = nil)
      template = product.variants.last
      product.variants.build do |new_variant|
        copy_template_fields(template, new_variant) if template
        new_variant.on_hand_desired = 0
        # Integer producer_id explicitly overrides the template's enterprise_id.
        # The view passes an AR relation (allowed_producers), not an ID, so this
        # guard ensures only a real ID overrides the copied value.
        new_variant.enterprise_id = producer_id if producer_id.is_a?(Integer)
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

      true
    end

    # Read only if variant comes from enterprise giving "create_linked_variants" permission and
    # isn't a variant we can manage
    def variant_readonly?(variant, allowed_producers, allowed_source_producers)
      return true if allowed_producers.exclude?(variant.enterprise) &&
                     allowed_source_producers.include?(variant.enterprise)

      false
    end

    def image_modal_resource_name(variant, product)
      resource_name = product.name

      variant&.display_name.present? ? "#{resource_name} - #{variant.display_name}" : resource_name
    end

    private

    def copy_template_fields(template, new_variant)
      NEW_VARIANT_TEMPLATE_FIELDS.each do |field|
        new_variant.public_send(:"#{field}=", template.public_send(field))
      end
    end
  end
end
