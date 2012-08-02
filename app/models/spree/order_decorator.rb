Spree::Order.class_eval do
  belongs_to :distributor

  def can_change_distributor?
    # Distributor may not be changed once an item has been added to the cart/order
    line_items.empty?
  end

  def distributor=(distributor)
    raise "You cannot change the distributor of an order with products" unless distributor == self.distributor || can_change_distributor?
    super(distributor)
  end

  def can_add_product_to_cart?(product)
    can_change_distributor? || product.distributors.include?(distributor)
  end

  def set_variant_attributes(variant, attributes)
    line_item = contains?(variant)

    line_item.assign_attributes(attributes)
    line_item.save!
  end



  before_validation :shipping_address_from_distributor

  private
  def shipping_address_from_distributor
    if distributor
      self.ship_address = distributor.pickup_address.clone

      if bill_address
        self.ship_address.firstname = bill_address.firstname
        self.ship_address.lastname = bill_address.lastname
        self.ship_address.phone = bill_address.phone
      end
    end
  end
end
