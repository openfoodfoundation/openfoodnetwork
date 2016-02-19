class Api::Admin::ExchangeSerializer < ActiveModel::Serializer
  attributes :id, :sender_id, :receiver_id, :incoming, :variants, :receival_instructions, :pickup_time, :pickup_instructions

  has_many :enterprise_fees, serializer: Api::Admin::BasicEnterpriseFeeSerializer

  def variants
    permitted = Spree::Variant.where("1=0")
    if object.incoming
      permitted = OpenFoodNetwork::OrderCyclePermissions.new(options[:current_user], object.order_cycle).
      visible_variants_for_incoming_exchanges_from(object.sender)
    else
      permitted = OpenFoodNetwork::OrderCyclePermissions.new(options[:current_user], object.order_cycle).
      visible_variants_for_outgoing_exchanges_to(object.receiver)
    end
    Hash[ object.variants.merge(permitted).map { |v| [v.id, true] } ]
  end
end
