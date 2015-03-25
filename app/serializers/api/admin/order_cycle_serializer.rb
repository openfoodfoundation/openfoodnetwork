class Api::Admin::OrderCycleSerializer < ActiveModel::Serializer
  attributes :id, :name, :orders_open_at, :orders_close_at, :coordinator_id, :exchanges
  attributes :visible_variants_for_outgoing_exchanges

  has_many :coordinator_fees, serializer: Api::IdSerializer

  def orders_open_at
    object.orders_open_at.to_s
  end

  def orders_close_at
    object.orders_close_at.to_s
  end

  def exchanges
    scoped_exchanges = OpenFoodNetwork::Permissions.new(options[:current_user]).order_cycle_exchanges(object).order('id ASC')
    ActiveModel::ArraySerializer.new(scoped_exchanges, {each_serializer: Api::Admin::ExchangeSerializer, current_user: options[:current_user] })
  end

  def visible_variants_for_outgoing_exchanges
    # For each enterprise that the current user is able to see in this order cycle,
    # work out which variants should be visible within outgoing exchanges from that enterprise
    visible = {}
    enterprises = OpenFoodNetwork::Permissions.new(options[:current_user]).order_cycle_enterprises_for(order_cycle: object)
    enterprises.each do |enterprise|
      variants = OpenFoodNetwork::Permissions.new(options[:current_user]).
        visible_variants_for_outgoing_exchanges_between(object.coordinator, enterprise, order_cycle: object).pluck(:id)
      visible[enterprise.id] = variants if variants.any?
    end
    visible
  end
end
