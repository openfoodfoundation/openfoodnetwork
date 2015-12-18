class Api::OrderSerializer < ActiveModel::Serializer
  attributes :id, :completed_at, :total, :state, :shipment_state, :outstanding_balance

  has_one :distributor, serializer: Api::IdNameSerializer

  def completed_at
    object.completed_at.blank? ? "" : object.completed_at.strftime("%F %T")
  end

end
