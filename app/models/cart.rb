class Cart < ActiveRecord::Base
  has_many   :orders, :class_name => 'Spree::Order'
  belongs_to :user,   :class_name => Spree.user_class

  def add_variant variant_id, quantity, currency
    variant = Spree::Variant.find(variant_id)
    variant.product.distributors.each do |distributor|
      order = create_or_find_order_for_distributor distributor, currency

      populator = Spree::OrderPopulator.new(order, currency)
      populator.populate({ :variants => { variant_id => quantity }, :distributor_id => distributor.id, :order_cycle_id => nil })
    end
  end

  def create_or_find_order_for_distributor distributor, currency
    order_for_distributor = orders.find { |order| order.distributor == distributor }
    unless order_for_distributor
      order_for_distributor = Spree::Order.create(:currency => currency, :distributor => distributor)
      order_for_distributor.distributor = distributor
      orders << order_for_distributor
    end

    order_for_distributor
  end
end
