class Api::OrdersByDistributorSerializer < ActiveModel::Serializer
  attributes :name, :id, :hash, :balance, :distributed_orders
  has_many :distributed_orders, serializer: Api::OrderSerializer

  def balance
    object.distributed_orders.map(&:outstanding_balance).reduce(:+).to_money.to_s
  end

  def hash
    object.to_param
  end

end
