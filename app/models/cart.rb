class Cart < ActiveRecord::Base
  has_many   :orders, :class_name => 'Spree::Order'
  belongs_to :user,   :class_name => Spree.user_class

  def add_variant variant_id, quantity, distributor, order_cycle, currency
    variant = Spree::Variant.find(variant_id)

    order = create_or_find_order_for_distributor distributor, order_cycle, currency

    @populator = Spree::OrderPopulator.new(order, currency)
    @populator.populate({ :variants => { variant_id => quantity } })
  end

  def create_or_find_order_for_distributor distributor, order_cycle, currency
    order_for_distributor = orders.find { |order| order.distributor == distributor && order.order_cycle == order_cycle }
    unless order_for_distributor
      order_for_distributor = Spree::Order.create(:currency => currency, :distributor => distributor)
      order_for_distributor.distributor = distributor
      order_for_distributor.order_cycle = order_cycle
      order_for_distributor.save!
      orders << order_for_distributor
    end

    order_for_distributor
  end

  def populate_errors
    @populator.errors
  end
end
