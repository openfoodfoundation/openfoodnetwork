Spree::Order.class_eval do
  belongs_to :distributor

  def can_change_distributor?
    # Distributor may not be changed once an item has been added to the cart/order
    line_items.empty?
  end

  def distributor=(distributor)
    raise "You cannot change the distributor of an order with products" unless can_change_distributor?
    super(distributor)
  end

  def can_add_product_to_cart?(product)
    can_change_distributor? || product.distributors.include?(distributor)
  end



  # before_validation :shipping_address_from_distributor

  private
  # def shipping_address_from_distributor
  #   if distributor
  #     ship_address.firstname = bill_address.firstname
  #     ship_address.lastname = bill_address.lastname
  #     ship_address.phone = bill_address.phone

  #     ship_address.address1 = distributor.pickup_address
  #     ship_address.city = distributor.city
  #     ship_address.zipcode = distributor.post_code
  #     ship_address.state = distributor.state
  #     ship_address.country_id = distributor.country_id
  #   end
  # end
end
