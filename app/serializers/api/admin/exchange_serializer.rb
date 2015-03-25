class Api::Admin::ExchangeSerializer < ActiveModel::Serializer
  attributes :id, :sender_id, :receiver_id, :incoming, :variants, :pickup_time, :pickup_instructions

  has_many :enterprise_fees, serializer: Api::Admin::EnterpriseFeeSerializer

  def variants
    permitted = Spree::Variant.where("1=0")
    if object.incoming
      permitted = OpenFoodNetwork::Permissions.new(options[:current_user]).
      visible_variants_for_incoming_exchanges_between(object.sender, object.receiver)
    else
      permitted = OpenFoodNetwork::Permissions.new(options[:current_user]).
      visible_variants_for_outgoing_exchanges_between(object.sender, object.receiver, order_cycle: object.order_cycle)
    end
    Hash[ object.variants.merge(permitted).map { |v| [v.id, true] } ]
  end
end
