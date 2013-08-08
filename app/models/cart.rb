class Cart < ActiveRecord::Base
  has_many :orders, :class_name => 'Spree::Order'
  belongs_to :user, :class_name => Spree.user_class

  def add_variant variant, quantity
    if orders.empty?
      order = Spree::Order.create
      order.add_variant(variant, quantity)
      orders << order
    end
  end
end
