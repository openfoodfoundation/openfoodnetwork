class Api::Admin::Reports::LineItemSerializer < ActiveModel::Serializer
  attributes :id, :quantity, :max_quantity, :price, :price_with_fees, :full_name, :cost, :distribution_fee, :currency, :scaled_final_weight_volume, :units_required, :remainder, :max_quantity_excess

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

  def units_required
    OpenFoodNetwork::Reports::BulkCoopReport.units_required([object])
  end

  def remainder
    OpenFoodNetwork::Reports::BulkCoopReport.remainder([object])
  end

  def max_quantity_excess
    OpenFoodNetwork::Reports::BulkCoopReport.max_quantity_excess([object])
  end
end
