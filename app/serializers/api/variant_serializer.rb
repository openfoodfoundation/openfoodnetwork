# frozen_string_literal: true

class Api::VariantSerializer < ActiveModel::Serializer
  attributes :id, :product_name, :sku,
             :options_text, :unit_value, :unit_description, :unit_to_display,
             :display_as, :display_name, :name_to_display,
             :price, :on_demand, :on_hand,
             :fees, :fees_name, :price_with_fees,
             :tag_list, :thumb_url,
             :unit_price_price, :unit_price_unit

  delegate :price, to: :object

  def fees
    options[:enterprise_fee_calculator]&.indexed_fees_by_type_for(object) ||
      object.fees_by_type_for(options[:current_distributor], options[:current_order_cycle])
  end

  def fees_name
    object.fees_name_by_type_for(options[:current_distributor], options[:current_order_cycle])
  end

  def price_with_fees
    if options[:enterprise_fee_calculator]
      object.price + options[:enterprise_fee_calculator].indexed_fees_for(object)
    else
      object.price_with_fees(options[:current_distributor], options[:current_order_cycle])
    end
  end

  def product_name
    object.product.name
  end

  # Used for showing/hiding variants in shopfront based on tag rules
  def tag_list
    return [] unless object.respond_to?(:tag_list)

    object.tag_list
  end

  def thumb_url
    object.product.image&.url(:mini) || Spree::Image.default_image_url(:mini)
  end

  def unit_price_price
    price_with_fees / (unit_price.denominator || 1)
  end

  delegate :unit, to: :unit_price, prefix: true

  private

  def unit_price
    @unit_price ||= UnitPrice.new(object)
  end
end
