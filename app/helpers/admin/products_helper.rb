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

    def prepare_new_variant(product, producer_options)
      # e.g producer_options = [['producer name', id]]
      product.variants.build do |new_variant|
        new_variant.supplier_id = producer_options.first.second if producer_options.one?
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

    # if user hasn't saved any preferences on products page and there's only one producer;
    # we need to hide producer column
    def hide_producer_column?(producer_options)
      spree_current_user.column_preferences.bulk_edit_product.empty? && producer_options.one?
    end

    # check if the user is in the "admins" group or if it's enabled for any of
    # the enterprises the user manages
    def variant_tag_enabled?(user)
      feature?(:variant_tag, user) || feature?(:variant_tag, *user.enterprises)
    end
  end
end
