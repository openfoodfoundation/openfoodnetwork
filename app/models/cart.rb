class Cart < ActiveRecord::Base
  has_many   :orders, :class_name => 'Spree::Order'
  belongs_to :user,   :class_name => Spree.user_class

  def add_products hash, currency
    if orders.empty?
      order = Spree::Order.create
      orders << order
    end

    order = orders.first
    populator = Spree::OrderPopulator.new(order, currency)
    populator.populate(hash)
  end
end
