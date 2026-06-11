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

    NEW_VARIANT_TEMPLATE_FIELDS = %i[
      tax_category_id
      primary_taxon_id
      supplier_id
      variant_unit
      variant_unit_scale
      variant_unit_name
      unit_value
      price
    ].freeze

    def prepare_new_variant(product, producer_id = nil)
      product.variants.build do |new_variant|
        template = product.variants.reject(&:new_record?).last
        copy_template_fields(template, new_variant) if template
        new_variant.on_hand_desired = 0
        # Integer producer_id explicitly overrides the template's supplier_id.
        # The view passes an AR relation (allowed_producers), not an ID, so this
        # guard ensures only a real ID overrides the copied value.
        new_variant.supplier_id = producer_id if producer_id.is_a?(Integer)
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

    def allowed_source_producers
      @allowed_source_producers ||= OpenFoodNetwork::Permissions.new(spree_current_user)
        .enterprises_granting_linked_variants
    end

    def managed_product_enterprises
      @managed_product_enterprises ||= OpenFoodNetwork::Permissions.new(spree_current_user)
        .managed_product_enterprises
    end

    private

    def copy_template_fields(template, new_variant)
      NEW_VARIANT_TEMPLATE_FIELDS.each do |field|
        next unless template.respond_to?(field) && new_variant.respond_to?(:"#{field}=")

        new_variant.public_send(:"#{field}=", template.public_send(field))
      end
    end

    # Query only name of the model to avoid loading the whole record
    def selected_option(id, model)
      return [] unless id

      name = model.where(id: id).pick(:name)
      return [] unless name

      [[name, id]]
    end
  end
end
