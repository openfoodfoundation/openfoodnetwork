class Api::Admin::ExchangeSerializer < ActiveModel::Serializer
  attributes :id, :sender_id, :receiver_id, :incoming, :variants, :pickup_time, :pickup_instructions

  has_many :enterprise_fees, serializer: Api::Admin::EnterpriseFeeSerializer

  def variants
    Hash[
      OpenFoodNetwork::Permissions.new(options[:current_user]).
      visible_variants_within(object).map { |v| [v.id, true] }
    ]
  end
end
