class Api::Admin::OrderCycleSerializer < ActiveModel::Serializer
  attributes :id, :name, :orders_open_at, :orders_close_at, :coordinator_id, :exchanges

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
end
