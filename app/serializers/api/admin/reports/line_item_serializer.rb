class Api::Admin::Reports::LineItemSerializer < ActiveModel::Serializer
  attributes :id, :quantity, :max_quantity, :price, :price_with_fees, :full_name, :cost, :distribution_fee, :currency, :scaled_final_weight_volume, :units_required, :remainder, :max_quantity_excess, :total_available, :total_units

  has_one :order, serializer: Api::Admin::IdSerializer
  has_one :product, serializer: Api::Admin::IdNameSerializer
  has_one :variant, serializer: Api::Admin::IdSerializer

  def price
    object.amount.to_f
  end

  def price_with_fees
    object.amount_with_adjustments.to_f
  end

  def cost
    object.price * object.quantity
  end

  def scaled_final_weight_volume
    OpenFoodNetwork::Reports::BulkCoopReport.scaled_final_weight_volume(object)
  end

  def total_available
    OpenFoodNetwork::Reports::BulkCoopReport.total_available([object])
  end

  def units_required
    OpenFoodNetwork::Reports::BulkCoopReport.units_required([object])
  end

  def remainder
    OpenFoodNetwork::Reports::BulkCoopReport.remainder([object])
  end

  def max_quantity_excess
    OpenFoodNetwork::Reports::BulkCoopReport.max_quantity_excess([object])
  end

  def total_units
    return " " if object.unit_value.nil?
    scale_factor = ( object.product.variant_unit == 'weight' ? 1000 : 1 )
    (object.quantity * object.unit_value / scale_factor).round 3
  end
end
