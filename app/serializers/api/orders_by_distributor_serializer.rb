module Api
  class OrdersByDistributorSerializer < ActiveModel::Serializer
    attributes :name, :id, :hash, :balance, :logo, :distributed_orders
    has_many :distributed_orders, serializer: Api::OrderSerializer

    def balance
      object.distributed_orders.map(&:outstanding_balance).reduce(:+).to_money.to_s
    end

    def hash
      object.to_param
    end

    def logo
      object.logo(:small) if object.logo?
    end
  end
end
