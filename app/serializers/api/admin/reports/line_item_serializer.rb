class Api::Admin::Reports::LineItemSerializer < ActiveModel::Serializer
  attributes :id, :quantity, :max_quantity, :price, :full_name, :cost, :cost_with_fees, :amount, :distribution_fee, :currency, :scaled_final_weight_volume, :units_required, :remainder, :max_quantity_excess, :total_available, :total_units, :paid?

  has_one :order, serializer: Api::Admin::IdSerializer
  has_one :product, serializer: Api::Admin::IdNameSerializer
  has_one :variant, serializer: Api::Admin::IdSerializer

  def cost
    object.price * object.quantity
  end

  def cost_with_fees
    object.amount_with_adjustments.to_f
  end

  def scaled_final_weight_volume
    (object.final_weight_volume || 0) / (object.product.variant_unit_scale || 1)
  end

  def total_available
    units_required * group_buy_unit_size
  end

  def units_required
    group_buy_unit_size.zero? ? 0 : ( scaled_final_weight_volume / group_buy_unit_size ).ceil
  end

  def remainder
    remainder = total_available - scaled_final_weight_volume
    remainder >= 0 ? remainder : ''
  end

  def max_quantity_excess
    max_quantity_amount - scaled_final_weight_volume
  end

  def total_units
    return " " if object.unit_value.nil?
    scale_factor = ( object.product.variant_unit == 'weight' ? 1000 : 1 )
    (object.quantity * object.unit_value / scale_factor).round 3
  end

  def paid?
    object.order.paid? ? 'Yes' : 'No'
  end

  private

  def group_buy_unit_size
    (object.variant.product.group_buy_unit_size || 0.0) / (object.product.variant_unit_scale || 1)
  end

  def scaled_unit_value
    (object.variant.unit_value || 0) / (object.variant.product.variant_unit_scale || 1)
  end

  def max_quantity_amount
    [object.max_quantity || 0, object.quantity || 0].max * scaled_unit_value
  end
end
